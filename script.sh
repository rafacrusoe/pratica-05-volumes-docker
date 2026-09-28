#!/usr/bin/env bash
set -euo pipefail

if [ -f /dados/hello.txt ]; then
  echo "Conteúdo de hello.txt:"
  cat /dados/hello.txt
fi

echo "Arquivo criado pelo container em $(date --iso-8601=seconds)" > /dados/novo_arquivo.txt
echo "Novo arquivo criado com sucesso!"
