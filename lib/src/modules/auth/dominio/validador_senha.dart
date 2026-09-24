/// Regra de senha usada tanto na recuperação (RF002) quanto na troca
/// obrigatória de senha no primeiro acesso: mínimo 8 caracteres, com
/// letra e número, diferente do CPF do usuário, com confirmação.
class ValidadorSenha {
  /// Retorna a mensagem de erro, ou `null` se a senha for válida.
  static String? validar(String senha, String confirmacao, {String? cpf}) {
    if (senha.length < 8) {
      return 'A senha deve ter no mínimo 8 caracteres.';
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(senha)) {
      return 'A senha deve conter pelo menos uma letra.';
    }
    if (!RegExp(r'[0-9]').hasMatch(senha)) {
      return 'A senha deve conter pelo menos um número.';
    }
    if (cpf != null) {
      final cpfLimpo = cpf.replaceAll(RegExp(r'[^0-9]'), '');
      if (cpfLimpo.isNotEmpty && senha == cpfLimpo) {
        return 'A senha não pode ser igual ao seu CPF.';
      }
    }
    if (senha != confirmacao) {
      return 'As senhas não coincidem.';
    }
    return null;
  }
}
