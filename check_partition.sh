#!/bin/bash

#################
# Configurações #
#################

# Definição de constantes
readonly SCRIPT_NAME=$(basename "$0")
readonly DATE_FORMAT='+%H:%M %d-%b-%Y'
readonly HTML_DATE_FORMAT='%Y%m%d'
readonly DISK_HISTORY_MINUTES=30

# Configurações de e-mail
readonly SENDER="no-reply@mail.com"
readonly RECIPIENT="$SENDER"  # Pode ser alterado conforme necessidade

# Arquivos temporários
readonly CURRENT_DATE=$(date "$DATE_FORMAT")
readonly TEMP_HTML="/tmp/relatorio_sistema_$(date +"$HTML_DATE_FORMAT").html"

#############
# Funções   #
#############

function log_message() {
    echo "[$(date "$DATE_FORMAT")] $1"
}

function check_dependencies() {
    local dependencies=("df" "top" "free" "sendmail")
    
    for cmd in "${dependencies[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            log_message "ERROR: Comando '$cmd' não encontrado. Por favor, instale-o."
            exit 1
        fi
    done
}

function get_disk_info() {
    df -h | awk '$NF!="/" {print $1,$2,$3,$4,$5,$6}' | sed 1d
}

function get_cpu_info() {
    top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8"%"}'
}

function get_memory_info() {
    free -h | awk 'NR==2{printf "Total: %s, Usado: %s, Livre: %s", $2, $3, $4}'
}

function collect_disk_history() {
    local history=""
    for i in $(seq $DISK_HISTORY_MINUTES -1 1); do
        history+=$(echo "$(date -d "$i minutes ago" +"%H:%M"),$(df -h | awk '$NF=="/" {print $5}' | cut -d'%' -f1)\n")
    done
    echo "$history"
}

function collect_system_info() {
    DISK_INFO=$(get_disk_info)
    CPU_INFO=$(get_cpu_info)
    MEM_INFO=$(get_memory_info)
    DISK_HISTORY=$(collect_disk_history)
}

function generate_html_report() {
    local template_file="$1"
    
    # Gera o HTML usando template externo (melhor manter em arquivo separado)
    cat << EOF > "$template_file"
<html>
<head>
    <meta charset="UTF-8">
    <title>Relatório - $(hostname)</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; background: #f4f4f4; }
        .container { padding: 20px; background: #fff; border-radius: 10px; box-shadow: 0 0 15px rgba(0,0,0,0.1); max-width: 900px; margin: auto; }
        h1 { color: #333; font-size: 1.8em; text-align: center; }
        p { color: #555; font-size: 1.1em; text-align: center; }
        table { width: 100%; border-collapse: collapse; margin-bottom: 20px; }
        th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #f0f0f0; color: #333; }
        .progress-container { width: 100%; background: #e0e0e0; border-radius: 5px; overflow: hidden; }
        .progress { height: 20px; transition: width 0.4s ease; border-radius: 5px; }
        .chart-container { position: relative; margin: auto; height: 400px; width: 80%; }
    </style>
</head>
<body>
<div class="container">
    <h1>Relatório de Sistema - $(hostname)</h1>
    <p>Relatório gerado em $CURRENT_DATE</p>
    
    <h2>Uso de Disco</h2>
    <table>
        <tr><th>Filesystem</th><th>Tamanho</th><th>Usado</th><th>Disponível</th><th>Uso%</th><th>Montado em</th></tr>
        $(echo "$DISK_INFO" | awk '{
            gsub(/%/,"",$5);
            color = $5 >= 90 ? "#FF4136" : ($5 >= 70 ? "#FF851B" : "#2ECC40");
            print "<tr><td>" $1 "</td><td>" $2 "</td><td>" $3 "</td><td>" $4 "</td><td><div class=\"progress-container\"><div class=\"progress\" style=\"width:" $5 "%; background-color:" color ";\">" $5 "%</div></div></td><td>" $6 "</td></tr>"
        }')
    </table>
    
    <h2>Uso de CPU</h2>
    <p><strong>Uso de CPU: </strong> $CPU_INFO</p>
    
    <h2>Uso de Memória</h2>
    <p><strong>$MEM_INFO</strong></p>
    
    <h2>Histórico de Uso de Disco (Últimos 30 minutos)</h2>
    <div class="chart-container">
        <canvas id="diskChart"></canvas>
    </div>
    <script>
        var ctx = document.getElementById('diskChart').getContext('2d');
        var diskChart = new Chart(ctx, {
            type: 'line',
            data: {
                labels: [$(echo "$DISK_HISTORY" | awk -F',' '{print "\"" $1 "\""}' | paste -sd,)],
                datasets: [{
                    label: 'Uso de Disco (%)',
                    data: [$(echo "$DISK_HISTORY" | awk -F',' '{print $2}' | paste -sd,)],
                    borderColor: 'rgba(54, 162, 235, 1)',
                    backgroundColor: 'rgba(54, 162, 235, 0.2)',
                    fill: true,
                    tension: 0.4
                }]
            },
            options: {
                responsive: true,
                plugins: {
                    legend: { position: 'top', labels: { boxWidth: 20 } },
                    tooltip: { callbacks: { label: function(context) { return context.raw + '%'; } } }
                },
                scales: {
                    y: { beginAtZero: true, max: 100, ticks: { callback: function(value) { return value + '%'; } } }
                }
            }
        });
    </script>
</div>
</body>
</html>
EOF
}

function send_email_report() {
    local html_file="$1"
    
    if [ ! -f "$html_file" ]; then
        log_message "ERROR: Arquivo HTML não encontrado: $html_file"
        return 1
    }

    sendmail -t << EOF
From: $SENDER
To: $RECIPIENT
Subject: Relatório de Sistema - $(hostname)
Content-Type: text/html; charset="UTF-8"

$(cat "$html_file")
EOF

    if [ $? -eq 0 ]; then
        log_message "Relatório enviado com sucesso para $RECIPIENT"
        return 0
    else
        log_message "ERROR: Falha ao enviar e-mail"
        return 1
    fi
}

function cleanup() {
    if [ -f "$TEMP_HTML" ]; then
        rm -f "$TEMP_HTML"
        log_message "Arquivos temporários removidos"
    fi
}

function main() {
    # Verifica dependências
    check_dependencies

    # Coleta informações do sistema
    collect_system_info
    
    # Gera relatório HTML
    generate_html_report "$TEMP_HTML"
    
    # Envia e-mail
    send_email_report "$TEMP_HTML"
    
    # Limpa arquivos temporários
    cleanup
}

############
# Execução #
############

# Tratamento de erros
set -e
trap 'log_message "ERROR: Script interrompido"; cleanup; exit 1' ERR

# Executa o programa principal
main

exit 0
