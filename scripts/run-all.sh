#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
EVIDENCE_DIR="$ROOT_DIR/evidencias"
VOLUME_NAME="dados_volume"
BASE_CONTAINER="volume-ubuntu"
APP_CONTAINER="volume-test-run"

mkdir -p "$EVIDENCE_DIR"
find "$EVIDENCE_DIR" -maxdepth 1 -type f ! -name '.gitkeep' -delete

cleanup() {
  docker rm -f "$BASE_CONTAINER" "$APP_CONTAINER" >/dev/null 2>&1 || true
  docker volume rm "$VOLUME_NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT

cd "$ROOT_DIR"

docker version --format 'Cliente={{.Client.Version}} Servidor={{.Server.Version}}' \
  | tee "$EVIDENCE_DIR/00-docker-version.txt"

{
  echo "AÇÃO 1 - CRIAÇÃO E MONTAGEM DO VOLUME"
  echo
  docker volume create "$VOLUME_NAME"
} | tee "$EVIDENCE_DIR/01-volume-create.txt"

docker volume ls --filter "name=$VOLUME_NAME" \
  | tee "$EVIDENCE_DIR/02-volume-list-after-create.txt"

docker run -d \
  --name "$BASE_CONTAINER" \
  --mount "type=volume,src=$VOLUME_NAME,target=/dados" \
  ubuntu:24.04 sleep infinity \
  | tee "$EVIDENCE_DIR/03-container-start.txt"

docker inspect --format '{{.Id}}' "$BASE_CONTAINER" \
  | tee "$EVIDENCE_DIR/04-container-id.txt"

docker inspect "$BASE_CONTAINER" --format '{{json .Mounts}}' \
  | jq . \
  | tee "$EVIDENCE_DIR/05-container-mounts.txt"

docker exec "$BASE_CONTAINER" bash -lc \
  'echo "Arquivo criado pelo primeiro contêiner" > /dados/container_origem.txt; ls -la /dados; cat /dados/container_origem.txt' \
  | tee "$EVIDENCE_DIR/06-write-from-container.txt"

MOUNTPOINT="$(docker volume inspect "$VOLUME_NAME" --format '{{.Mountpoint}}')"
{
  echo "Mountpoint: $MOUNTPOINT"
  echo "Conteúdo criado pelo contêiner e lido diretamente pelo host:"
  sudo cat "$MOUNTPOINT/container_origem.txt"
  echo
  echo "Arquivo criado diretamente pelo host" | sudo tee "$MOUNTPOINT/hello.txt"
  echo "Conteúdo criado pelo host e lido dentro do contêiner:"
  docker exec "$BASE_CONTAINER" cat /dados/hello.txt
} | tee "$EVIDENCE_DIR/07-sharing-both-directions.txt"

{
  echo "AÇÃO 2 - PERSISTÊNCIA E COMPARTILHAMENTO DE DADOS"
  echo
  echo "Dockerfile"
  sed -n '1,120p' Dockerfile
} | tee "$EVIDENCE_DIR/08-dockerfile.txt"

{
  echo "script.sh"
  sed -n '1,160p' script.sh
} | tee "$EVIDENCE_DIR/09-script-sh.txt"

docker build -t volume-test . 2>&1 \
  | tee "$EVIDENCE_DIR/10-build.txt"

docker run \
  --name "$APP_CONTAINER" \
  --mount "type=volume,src=$VOLUME_NAME,dst=/dados" \
  volume-test 2>&1 \
  | tee "$EVIDENCE_DIR/11-volume-test-run.txt"

docker logs "$APP_CONTAINER" \
  | tee "$EVIDENCE_DIR/12-volume-test-logs.txt"

{
  echo "Conteúdo de novo_arquivo.txt lido diretamente pelo host:"
  sudo cat "$MOUNTPOINT/novo_arquivo.txt"
} | tee "$EVIDENCE_DIR/13-host-read-new-file.txt"

docker ps -a --filter "name=$APP_CONTAINER" \
  --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' \
  | tee "$EVIDENCE_DIR/14-container-status.txt"

docker rm -f "$BASE_CONTAINER" "$APP_CONTAINER" \
  | tee "$EVIDENCE_DIR/15-original-containers-removed.txt"

docker run --rm \
  --mount "type=volume,src=$VOLUME_NAME,target=/dados" \
  ubuntu:24.04 bash -lc \
  'echo "Arquivos persistentes:"; ls -la /dados; echo; cat /dados/container_origem.txt; cat /dados/hello.txt; cat /dados/novo_arquivo.txt' \
  | tee "$EVIDENCE_DIR/16-persistence-verifier.txt"

{
  echo "AÇÃO 3 - ADMINISTRAÇÃO E REMOÇÃO DO VOLUME"
  echo
  docker volume inspect "$VOLUME_NAME"
} | tee "$EVIDENCE_DIR/17-volume-inspect.txt"

docker volume ls \
  | tee "$EVIDENCE_DIR/18-volume-list-before-remove.txt"

docker volume rm "$VOLUME_NAME" \
  | tee "$EVIDENCE_DIR/19-volume-remove.txt"

docker volume ls --filter "name=$VOLUME_NAME" \
  | tee "$EVIDENCE_DIR/20-volume-list-after-remove.txt"

if docker volume inspect "$VOLUME_NAME" >"$EVIDENCE_DIR/21-volume-absent-check.txt" 2>&1; then
  echo "ERRO: o volume ainda existe" | tee -a "$EVIDENCE_DIR/21-volume-absent-check.txt"
  exit 1
else
  {
    cat "$EVIDENCE_DIR/21-volume-absent-check.txt"
    echo "volume_removido=sim"
  } | tee "$EVIDENCE_DIR/21-volume-absent-check.tmp"
  mv "$EVIDENCE_DIR/21-volume-absent-check.tmp" "$EVIDENCE_DIR/21-volume-absent-check.txt"
fi

docker ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' \
  | tee "$EVIDENCE_DIR/22-final-containers.txt"

cat > "$EVIDENCE_DIR/resumo.txt" <<'SUMMARY'
Prática 05 concluída com sucesso.
- Volume dados_volume criado e montado em /dados.
- Compartilhamento em ambos os sentidos entre contêiner e host confirmado.
- Imagem volume-test construída e executada.
- Dados preservados após a finalização e remoção dos contêineres originais.
- Volume inspecionado, listado, removido e ausência confirmada.
SUMMARY

cat "$EVIDENCE_DIR/resumo.txt"
