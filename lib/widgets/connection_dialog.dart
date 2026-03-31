import 'package:flutter/material.dart';

class ConnectionFormDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  
  // VARIABLES OPCIONALES PARA MODO EDICIÓN
  final String? initialHost;
  final String? initialUser;
  final String? initialPass;
  final String? initialName;

  final void Function(String host, String username, String password, int port) onSubmit;

  const ConnectionFormDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onSubmit,
    this.initialHost,
    this.initialUser,
    this.initialPass,
    this.initialName,
  });

  @override
  State<ConnectionFormDialog> createState() => _ConnectionFormDialogState();
}

class _ConnectionFormDialogState extends State<ConnectionFormDialog> {
  final _formKey = GlobalKey<FormState>();

  bool isPasswordSelected = true;
  bool isPasswordVisible = false;

  late TextEditingController _ipController;
  late TextEditingController _userController;
  late TextEditingController _passController;
  late TextEditingController _nameController; 

  @override
  void initState() {
    super.initState();
    // PRECARGAMOS LOS DATOS EN LOS CAMPOS DE TEXTO
    _ipController = TextEditingController(text: widget.initialHost ?? '');
    _userController = TextEditingController(text: widget.initialUser ?? '');
    _passController = TextEditingController(text: widget.initialPass ?? '');
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _ipController.dispose();
    _userController.dispose();
    _passController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateIpOrDomain(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La IP o Dominio es obligatoria';
    }
    final ipRegExp = RegExp(r'^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$');
    final domainRegExp = RegExp(r'^([a-zA-Z0-9]+(-[a-zA-Z0-9]+)*\.)+[a-zA-Z]{2,}$');
    
    if (!ipRegExp.hasMatch(value.trim()) && !domainRegExp.hasMatch(value.trim())) {
      return 'Formato de IP o Dominio invalido';
    }
    return null;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF151821),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Center(
                        child: Text(
                          widget.title,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.white54, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    widget.subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),

                _buildLabel('Nombre (Alias)'),
                _buildTextField(
                  'Ej: Servidor Principal', 
                  controller: _nameController,
                  validator: (val) => _validateRequired(val, 'El nombre/alias'),
                ),
                const SizedBox(height: 16),

                _buildLabel('Dirección IP / Dominio'),
                _buildTextField(
                  'Ej: 192.168.1.100', 
                  controller: _ipController,
                  validator: _validateIpOrDomain,
                ),
                const SizedBox(height: 16),

                _buildLabel('Usuario'),
                _buildTextField(
                  'Ej: root, admin', 
                  controller: _userController,
                  validator: (val) => _validateRequired(val, 'El usuario'),
                ),
                const SizedBox(height: 16),

                _buildLabel('Método de autenticación'),
                const SizedBox(height: 8),
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2230),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPasswordSelected = true),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isPasswordSelected ? const Color(0xFF7B52FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline, color: isPasswordSelected ? Colors.white : Colors.white54, size: 16),
                                const SizedBox(width: 8),
                                Text('Contraseña', style: TextStyle(color: isPasswordSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isPasswordSelected = false),
                          child: Container(
                            decoration: BoxDecoration(
                              color: !isPasswordSelected ? const Color(0xFF7B52FF) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.key, color: !isPasswordSelected ? Colors.white : Colors.white54, size: 16),
                                const SizedBox(width: 8),
                                Text('SSH Key', style: TextStyle(color: !isPasswordSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabel(isPasswordSelected ? 'Contraseña' : 'Clave SSH / Ruta del archivo'),
                _buildTextField(
                  isPasswordSelected ? 'Ingresa la contraseña' : 'Pega tu clave o selecciona archivo',
                  controller: _passController,
                  isPassword: isPasswordSelected,
                  validator: (val) => _validateRequired(val, isPasswordSelected ? 'La contraseña' : 'La clave SSH'),
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancelar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF9B63FF), Color(0xFF704EFE)]),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextButton(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              widget.onSubmit(
                                _ipController.text.trim(),
                                _userController.text.trim(),
                                _passController.text,
                                22, 
                              );
                            }
                          },
                          child: Text(widget.buttonText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(String hint, {required TextEditingController controller, bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E2230),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 12),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF7B52FF)),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white38, size: 20),
                onPressed: () => setState(() => isPasswordVisible = !isPasswordVisible),
              )
            : null,
      ),
    );
  }
}