import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme.dart';

/// A 4-box OTP-style PIN input widget.
/// Each box accepts exactly one digit and auto-focuses the next box.
/// [onCompleted] is called with the full 4-digit PIN when all boxes are filled.
class PinInputWidget extends StatefulWidget {
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;

  const PinInputWidget({
    super.key,
    required this.onCompleted,
    this.onChanged,
  });

  @override
  State<PinInputWidget> createState() => _PinInputWidgetState();
}

class _PinInputWidgetState extends State<PinInputWidget> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 4; i++) {
      _focusNodes[i].addListener(() {
        if (_focusNodes[i].hasFocus) {
          _controllers[i].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[i].text.length,
          );
        }
      });
    }
  }

  String get _pin => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.isNotEmpty) {
      // Keep only the last character if multiple are entered (e.g. paste or fast typing)
      if (value.length > 1) {
        _controllers[index].text = value.substring(value.length - 1);
        _controllers[index].selection = TextSelection.fromPosition(
            TextPosition(offset: _controllers[index].text.length));
      }

      if (index < 3) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    widget.onChanged?.call(_pin);
    if (_pin.length == 4) {
      widget.onCompleted(_pin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        return Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          child: TextField(
            controller: _controllers[index],
            focusNode: _focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.phone,
            autofocus: index == 0,
            textInputAction:
                index < 3 ? TextInputAction.next : TextInputAction.done,
            obscureText: true,
            obscuringCharacter: '*',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.black,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(
                  2), // Allow 2 for easier replacement logic
            ],
            decoration: const InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: AppTheme.gray200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide:
                    BorderSide(color: AppTheme.primaryYellow, width: 1.5),
              ),
            ),
            onChanged: (v) => _onChanged(index, v),
          ),
        );
      }),
    );
  }
}
