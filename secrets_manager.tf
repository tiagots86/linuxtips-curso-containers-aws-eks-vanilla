resource "aws_secretsmanager_secret" "teste" {
  name = "chip-teste"
}

resource "aws_secretsmanager_secret_version" "teste" {
  secret_id     = aws_secretsmanager_secret.teste.id
  secret_string = "BAR"
}