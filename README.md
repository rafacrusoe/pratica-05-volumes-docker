# Prática 05 - Volumes no Docker

Este projeto executa e documenta as três ações do roteiro da disciplina Práticas Integradas Full Cycle:

- criação e montagem do volume `dados_volume` em um contêiner Ubuntu;
- compartilhamento de arquivos nos dois sentidos entre contêiner e host, com validação da persistência;
- inspeção, listagem e remoção segura do volume.

## Estrutura

- `Dockerfile`: cria a imagem `volume-test` indicada no roteiro;
- `script.sh`: lê `hello.txt` e grava `novo_arquivo.txt` no volume;
- `scripts/run-all.sh`: automatiza os comandos e gera as evidências;
- `.github/workflows/pratica-docker.yml`: executa a prática no GitHub Actions;
- `evidencias/`: recebe os resultados de cada comando.

## Execução

```bash
chmod +x script.sh scripts/run-all.sh
./scripts/run-all.sh
```

No GitHub Actions, o contêiner Ubuntu da Ação 1 é iniciado em segundo plano com `sleep infinity`, pois o executor não disponibiliza um terminal interativo. O volume, o ponto de montagem e os comandos validados permanecem equivalentes ao roteiro.
