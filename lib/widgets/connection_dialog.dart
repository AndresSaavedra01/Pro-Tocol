import 'package:flutter/material.dart';

class ConnectionFormDialog extends StatefulWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onSubmit;

  const ConnectionFormDialog({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onSubmit,
  });

  @override
  State<ConnectionFormDialog> createState() => _ConnectionFormDialogState();
}

class _ConnectionFormDialogState extends State<ConnectionFormDialog> {
  bool isPasswordSelected = true;
  bool isPasswordVisible = false;

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera
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

              // Campos
              _buildLabel('Nombre'),
              _buildTextField('Ej: Servidor Principal'),
              const SizedBox(height: 16),

              _buildLabel('Dirección IP'),
              _buildTextField('Ej: 192.168.1.100'),
              const SizedBox(height: 16),

              _buildLabel('Usuario'),
              _buildTextField('Ej: root, admin'),
              const SizedBox(height: 16),

              // Toggle Contraseña / SSH Key
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
                isPassword: isPasswordSelected,
              ),
              const SizedBox(height: 24),

              // Botones de acción
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
                          widget.onSubmit();
                          Navigator.pop(context); // Cierra el modal tras enviar
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
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(String hint, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: const Color(0xFF1E2230),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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