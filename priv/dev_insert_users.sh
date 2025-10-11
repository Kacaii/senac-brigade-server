#!/bin/bash

# Admin
http --session=./priv/session.json --form POST :8000/user/login matricula='000' senha='aluno'

# Firefighter
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Pedro Anthony" matricula="001" telefone="0000000001" email="anthony@email" \
  senha="aluno" confirma_senha="aluno" cargo="bombeiro"

# Administrator
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Ana Maria Silva" matricula="002" telefone="0000000002" email="ana2@email" \
  senha="aluno" confirma_senha="aluno" cargo="administrador"

# Analyst
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Carlos Eduardo Santos" matricula="003" telefone="0000000003" email="carlos3@email" \
  senha="aluno" confirma_senha="aluno" cargo="analista"

# Captain
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Maria Fernanda Lima" matricula="004" telefone="0000000004" email="maria4@email" \
  senha="aluno" confirma_senha="aluno" cargo="capitão"

# Developer
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="João Pedro Oliveira" matricula="005" telefone="0000000005" email="joao5@email" \
  senha="aluno" confirma_senha="aluno" cargo="desenvolvedor"

# Sergeant
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Laura Cristina Souza" matricula="006" telefone="0000000006" email="laura6@email" \
  senha="aluno" confirma_senha="aluno" cargo="sargento"

# Firefighter
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Miguel Augusto Costa" matricula="007" telefone="0000000007" email="miguel7@email" \
  senha="aluno" confirma_senha="aluno" cargo="bombeiro"

# Analyst
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Sofia Beatriz Rocha" matricula="008" telefone="0000000008" email="sofia8@email" \
  senha="aluno" confirma_senha="aluno" cargo="analista"

# Developer
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Rafael Henrique Alves" matricula="009" telefone="0000000009" email="rafael9@email" \
  senha="aluno" confirma_senha="aluno" cargo="desenvolvedor"

# Administrator
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Isabel Cristina Martins" matricula="010" telefone="0000000010" email="isabel10@email" \
  senha="aluno" confirma_senha="aluno" cargo="administrador"

# Sergeant
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="André Luiz Ferreira" matricula="011" telefone="0000000011" email="andre11@email" \
  senha="aluno" confirma_senha="aluno" cargo="sargento"

# Firefighter
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Camila Santos Rodrigues" matricula="012" telefone="0000000012" email="camila12@email" \
  senha="aluno" confirma_senha="aluno" cargo="bombeiro"

# Developer
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Bruno Oliveira Silva" matricula="013" telefone="0000000013" email="bruno13@email" \
  senha="aluno" confirma_senha="aluno" cargo="desenvolvedor"

# Captain
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Juliana Costa Pereira" matricula="014" telefone="0000000014" email="juliana14@email" \
  senha="aluno" confirma_senha="aluno" cargo="capitão"

# Analyst
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Ricardo Almeida Souza" matricula="015" telefone="0000000015" email="ricardo15@email" \
  senha="aluno" confirma_senha="aluno" cargo="analista"

# Administrator
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Fernanda Dias Castro" matricula="016" telefone="0000000016" email="fernanda16@email" \
  senha="aluno" confirma_senha="aluno" cargo="administrador"

# Sergeant
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Diego Martins Nunes" matricula="017" telefone="0000000017" email="diego17@email" \
  senha="aluno" confirma_senha="aluno" cargo="sargento"

# Firefighter
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Patricia Lima Barbosa" matricula="018" telefone="0000000018" email="patricia18@email" \
  senha="aluno" confirma_senha="aluno" cargo="bombeiro"

# Developer
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Lucas Ribeiro Cardoso" matricula="019" telefone="0000000019" email="lucas19@email" \
  senha="aluno" confirma_senha="aluno" cargo="desenvolvedor"

# Analyst
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Amanda Torres Monteiro" matricula="020" telefone="0000000020" email="amanda20@email" \
  senha="aluno" confirma_senha="aluno" cargo="analista"
