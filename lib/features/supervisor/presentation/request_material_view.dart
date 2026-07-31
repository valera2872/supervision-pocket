import 'package:flutter/material.dart';
import 'package:supervision_pocket/app/theme/app_colors.dart';
import 'package:supervision_pocket/features/supervisor/domain/request_material.dart';

class RequestMaterialView extends StatelessWidget {
  const RequestMaterialView({
    required this.contextText,
    this.initiallyExpanded = false,
    super.key,
  });

  final String contextText;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final material = RequestMaterial.parse(contextText);
    if (material.sections.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        leading: const Icon(Icons.description_outlined, color: AppColors.navy),
        title: const Text('Материал запроса'),
        subtitle: Text(
          material.isStructured
              ? '${material.sections.length} разделов · получено от супервизанта'
              : 'Получено от супервизанта',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          for (final section in material.sections)
            Padding(
              padding: const EdgeInsets.only(top: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.label,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(section.value),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
