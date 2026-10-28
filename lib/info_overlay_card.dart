import 'package:flutter/material.dart';

import 'sculpture_info.dart';
import 'theme.dart';

class InfoOverlayCard extends StatefulWidget {
  final SculptureInfo info;
  final VoidCallback onDismiss;
  const InfoOverlayCard({
    super.key,
    required this.info,
    required this.onDismiss,
  });

  @override
  State<InfoOverlayCard> createState() => _InfoOverlayCardState();
}

class _InfoOverlayCardState extends State<InfoOverlayCard> {
  bool _expanded = false;

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(top: 14, bottom: 4),
    child: Text(
      t.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        letterSpacing: 1.4,
        fontWeight: FontWeight.w700,
        color: AppColors.terracotta,
      ),
    ),
  );

  Widget _body(String t) =>
      Text(t, style: const TextStyle(fontSize: 14, height: 1.45));

  String _title(String k) =>
      k.isEmpty ? k : k[0].toUpperCase() + k.substring(1).replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final i = widget.info;
    final maxH = MediaQuery.of(context).size.height * 0.5;

    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.gold.withValues(alpha: 0.2),
          ),
          child: const Icon(
            Icons.info_outline_rounded,
            color: AppColors.terracotta,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i.name,
                style: const TextStyle(
                  fontFamily: kSerif,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (i.period != null) ...[
                const SizedBox(height: 4),
                Text(
                  i.period!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.gold,
                  ),
                ),
              ],
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: _expanded ? 'Collapse' : 'Dismiss',
          icon: Icon(
            _expanded ? Icons.keyboard_arrow_down_rounded : Icons.close_rounded,
          ),
          onPressed: _expanded
              ? () => setState(() => _expanded = false)
              : widget.onDismiss,
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.ivory.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: _expanded ? null : () => setState(() => _expanded = true),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  header,
                  if (!_expanded) ...[
                    if (i.significance != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        i.significance!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14, height: 1.4),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          'Tap for details',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.terracotta,
                          ),
                        ),
                        Icon(
                          Icons.expand_less_rounded,
                          size: 16,
                          color: AppColors.terracotta,
                        ),
                      ],
                    ),
                  ] else
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxH),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (i.significance != null) ...[
                              _label('Significance'),
                              _body(i.significance!),
                            ],
                            if (i.description != null) ...[
                              _label('About'),
                              _body(i.description!),
                            ],
                            if (i.mythology != null) ...[
                              _label('Mythology'),
                              _body(i.mythology!),
                            ],
                            for (final e in i.extras.entries) ...[
                              _label(_title(e.key)),
                              _body(e.value),
                            ],
                            const SizedBox(height: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
