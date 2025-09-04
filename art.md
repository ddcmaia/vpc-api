# Construindo VPCs sob demanda com AWS

ddcmaia
2 min read · Just now

Quando quis gerar redes isoladas rapidamente sem abrir o console da AWS, encontrei este repositório. Ele usa Terraform para expor uma API serverless que cria VPCs conforme a demanda, guardando os metadados em DynamoDB.

## Por que experimentar
- Aprender: ajuda a entender como API Gateway, Lambda e Cognito se combinam.
- Testar: é fácil modificar os módulos e ver novas topologias de rede surgirem.
- Explorar IaC: tudo é descrito em código, ideal para quem curte AWS e automatiza tudo.
- Compartilhar o desafio: ótimo exemplo para discussões sobre segurança e multi-conta.

## Como funciona
O Terraform provisiona:
- API Gateway protegido por Cognito.
- Funções Lambda que criam e consultam VPCs.
- DynamoDB para persistir o estado.

Chamadas `POST /vpcs` criam VPCs com sub-redes e devolvem o identificador; `GET /vpcs/<id>` retorna os detalhes armazenados.

## Executando localmente
1. Configure suas credenciais AWS.
2. Crie o bucket S3 para armazenar o estado.
3. Rode `terraform init`, `plan` e `apply`.
4. Obtenha os outputs e gere um token via Cognito.
5. Invoque a API com `curl` para criar e listar VPCs.

## Reflexões
Não é uma solução de produção, mas um caminho rápido para explorar como a AWS se comporta sob demanda. Serve de base para experimentos com Helm, pipelines ou testes de infraestrutura.

Mantenho essas notas abertas para que qualquer pessoa interessada em AWS possa aproveitar e adaptar ao seu fluxograma.
