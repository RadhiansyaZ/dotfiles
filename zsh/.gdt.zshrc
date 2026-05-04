## Docker Compose
alias dcu="docker compose -f deploy/docker-compose.base.yml up -d"
alias dcd="docker compose -f deploy/docker-compose.base.yml down"

## Redis

# $1 = port
redis-connect() {
  redis-cli -h localhost -p ${1} -a $(pass gdt/infra/devstg/redis/user)
}

# kubectl exec -it -n redis redis-master-0 -- redis-cli

## Teleport
KUBE_DEV="ack-backend-jakarta-dev"
KUBE_STAGING="ack-apps-jakarta-staging"

alias tsh-login="tsh kube login"
alias kpf-redis="kubectl port-forward -n redis svc/redis-master :6379"

# $1 = name
kpf() {
  kubectl port-forward -n service-${1} svc/service-${1} :80
}
