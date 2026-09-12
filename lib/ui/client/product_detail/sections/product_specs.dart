import 'package:flutter/material.dart';
import '../../../../core/theme.dart';

class ProductSpecs extends StatelessWidget {
  final Map<String, String> specs;
  const ProductSpecs({super.key, required this.specs});

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) return const SizedBox.shrink();
    final entries = specs.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spécifications',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: context.softShadow,
          ),
          child: Column(
            children: List.generate(entries.length, (i) {
              final isLast = i == entries.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entries[i].key,
                            style: TextStyle(
                              fontSize: 13,
                              color: context.textMuted,
                            ),
                          ),
                        ),
                        Text(
                          entries[i].value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color:
                          context.textMuted.withValues(alpha: 0.15),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }
}