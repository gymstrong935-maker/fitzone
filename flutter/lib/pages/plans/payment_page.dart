import 'package:flutter/material.dart';

import 'package:fitzone/models/trainer.dart';

class PaymentPage extends StatefulWidget {
  final Trainer entrenador;

  const PaymentPage({
    super.key,
    required this.entrenador,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String? metodoSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF080808),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: Colors.white24,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Método de Pago',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    'Plan con ${widget.entrenador.nombre}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.entrenador.precio,
                        style: const TextStyle(
                          color: Color(0xFF05C8D8),
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(width: 8),

                      const Padding(
                        padding: EdgeInsets.only(bottom: 5),
                        child: Text(
                          '/mes',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  _crearMetodo(
                    icono: Icons.credit_card,
                    texto: 'Tarjeta de Crédito',
                  ),

                  _crearMetodo(
                    icono: Icons.credit_card,
                    texto: 'Tarjeta de Débito',
                  ),

                  _crearMetodo(
                    icono: Icons.account_balance,
                    texto: 'Transferencia Bancaria',
                  ),

                  _crearMetodo(
                    icono: Icons.account_balance_wallet,
                    texto: 'PayPal',
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: Colors.white12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Cancelar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: metodoSeleccionado == null
                                ? null
                                : () {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Pago confirmado con '
                                          '$metodoSeleccionado',
                                        ),
                                      ),
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF05C8D8),
                              foregroundColor: Colors.black,
                              disabledBackgroundColor:
                                  Colors.white12,
                              disabledForegroundColor:
                                  Colors.white38,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(25),
                              ),
                            ),
                            child: const Text(
                              'Confirmar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
      ),
    );
  }

  Widget _crearMetodo({
    required IconData icono,
    required String texto,
  }) {
    final bool seleccionado = metodoSeleccionado == texto;

    return GestureDetector(
      onTap: () {
        setState(() {
          metodoSeleccionado = texto;
        });
      },
      child: Container(
        width: double.infinity,
        height: 68,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 18,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF151515),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: seleccionado
                ? const Color(0xFF05C8D8)
                : Colors.white12,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icono,
              color: const Color(0xFF05C8D8),
              size: 24,
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            if (seleccionado)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF05C8D8),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}