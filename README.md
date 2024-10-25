# Projeto Infra Auto

Este projeto utiliza Terraform para provisionar uma instância no Azure e Ansible para configurar um servidor web.

## Estrutura do Projeto

- **Terraform**: Provisiona a infraestrutura no Azure.
- **Ansible**: Configura o servidor web na instância provisionada.

## Arquivos

- `main.tf`: Arquivo principal do Terraform para provisionamento da infraestrutura.
- `variables.tf`: Definição de variáveis para o Terraform.
- `outputs.tf`: Saídas do Terraform.
- `playbook_nginx_instance.yml`: Playbook Ansible para instalar o Nginx na própria instância.
- `playbook_nginx_docker.yml`: Playbook Ansible para instalar o Nginx dentro de um container Docker na instância.

## Como Usar

### Provisionar Infraestrutura

1. Inicialize o Terraform:
    ```sh
    terraform init
    ```

2. Aplique a configuração do Terraform:
    ```sh
    terraform apply
    ```

### Configurar Servidor Web

1. Execute o playbook para instalar o Nginx na instância:
    ```sh
    ansible-playbook playbook_nginx_instance.yml
    ```

2. Ou execute o playbook para instalar o Nginx dentro de um container Docker:
    ```sh
    ansible-playbook playbook_nginx_docker.yml
    ```

## Requisitos

- Terraform v1.0+
- Ansible v2.9+
- Azure CLI configurado

## Contribuição

Contribuições são bem-vindas! Sinta-se à vontade para abrir issues e pull requests.

