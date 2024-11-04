# Monitor de Sistema e Gerador de Relatórios

## Descrição
Este script bash foi desenvolvido para monitorar recursos do sistema Linux e gerar relatórios detalhados em formato HTML, enviando-os por e-mail. O relatório inclui informações sobre uso de disco, CPU e memória, além de um gráfico histórico do uso do disco nas últimas 30 minutos.

## Funcionalidades
- Monitoramento de:
  - Uso de disco (espaço total, usado e disponível)
  - Utilização de CPU
  - Estado da memória (total, usada e livre)
  - Histórico de uso do disco nos últimos 30 minutos

- Geração de relatório HTML com:
  - Layout responsivo e moderno
  - Barras de progresso coloridas (verde, amarelo, vermelho) baseadas no nível de utilização
  - Gráfico interativo do histórico de uso do disco
  - Formatação clara e organizada das informações

- Envio automático do relatório por e-mail

## Requisitos
O script necessita dos seguintes comandos instalados no sistema:
- df (informações do sistema de arquivos)
- top (informações de CPU)
- free (informações de memória)
- sendmail (envio de e-mails)

## Configuração
As principais configurações podem ser ajustadas no início do script:
readonly SENDER="no-reply@mail.com"        # E-mail remetente
readonly RECIPIENT="$SENDER"               # E-mail destinatário
readonly DISK_HISTORY_MINUTES=30           # Período do histórico em minutos

## Como usar
1. Dê permissão de execução ao script:
chmod +x check_partition.sh

2. Execute o script:
./check_partition.sh

## Saída
- Gera um arquivo HTML temporário em /tmp/
- Envia o relatório por e-mail para o destinatário configurado
- Remove automaticamente os arquivos temporários após o envio

## Tratamento de Erros
- Verifica dependências antes da execução
- Possui sistema de log para rastreamento de erros
- Limpa arquivos temporários mesmo em caso de falha

## Observações
- O script utiliza a biblioteca Chart.js para geração de gráficos
- O relatório é otimizado para visualização em navegadores modernos
- As cores das barras de progresso mudam conforme o nível de utilização:
  - Verde: < 70%
  - Amarelo: entre 70% e 90%
  - Vermelho: > 90%
