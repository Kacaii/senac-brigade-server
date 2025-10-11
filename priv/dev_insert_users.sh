#!/bin/bash

# Admin
http --session=./priv/session.json --form POST :8000/user/login matricula='000' senha='aluno'

# Firefighter
http --session=./priv/session.json --form POST :8000/admin/signup \
  nome="Pedro Anthony" matricula="001" telefone="0000000001" email="anthony@email" \
  senha="aluno" confirma_senha="aluno" cargo="bombeiro"
