import 'package:flutter/material.dart';
import '../models/beauty_models.dart';
import '../screens/service_details_screen.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'service_mapper.dart';

/// Services still load from Firestore through your ServiceRepository.
class ServiceListPage extends StatefulWidget {
  final String? initialCategory;
  const ServiceListPage({super.key, this.initialCategory});

  @override
  State<ServiceListPage> createState() => _ServiceListPageState();
}

class _ServiceListPageState extends State<ServiceListPage> {
  late Future<List<ServiceItem>> _future = loadServices();
  late String _cat = widget.initialCategory ?? 'All';
  String _query = '';
  static const _cats = ['All', 'Hair', 'Nails', 'Skin', 'Massage'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(children: [
                if (Navigator.canPop(context)) ...[
                  RoundIconButton(
                      icon: Icons.arrow_back_ios_new_rounded, onTap: () => Navigator.pop(context)),
                  const SizedBox(width: 12),
                ],
                Text('Our Services', style: AppText.display(30)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: TextField(
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search a treatment…',
                  hintStyle: AppText.body(15, color: AppColors.muted),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.rose),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: _cats.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final c = _cats[i];
                  final sel = c == _cat;
                  return GestureDetector(
                    onTap: () => setState(() => _cat = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryDark : AppColors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(c,
                          style: AppText.body(14,
                              color: sel ? AppColors.cream : AppColors.cocoa, w: FontWeight.w600)),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<ServiceItem>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.rose));
                  }
                  if (snap.hasError) {
                    return ErrorRetry(
                      message: 'Could not load services.',
                      onRetry: () => setState(() => _future = loadServices()),
                    );
                  }
                  final items = (snap.data ?? []).where((s) {
                    final okCat = _cat == 'All' || s.category == _cat;
                    final okQ = _query.isEmpty || s.name.toLowerCase().contains(_query);
                    return okCat && okQ;
                  }).toList();
                  if (items.isEmpty) {
                    return Center(
                        child: Text('No services found.',
                            style: AppText.body(15, color: AppColors.muted)));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) => _ServiceCard(item: items[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final ServiceItem item;
  const _ServiceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => ServiceDetailsScreen(service: item))),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.sand),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ServiceImage(
              url: item.imageUrl, category: item.category, width: 96, height: 112, radius: 20),
          const SizedBox(width: 14),
          Expanded(
            child: SizedBox(
              height: 112,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.display(18)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text('${item.duration} minutes',
                        style: AppText.body(12.5, color: AppColors.muted)),
                  ]),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body(13, color: AppColors.muted)),
                  ),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(peso(item.price),
                        style: AppText.display(19, color: AppColors.rose, w: FontWeight.w700)),
                    Container(
                      width: 32,
                      height: 32,
                      decoration:
                          const BoxDecoration(color: AppColors.blush, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward_rounded,
                          size: 18, color: AppColors.cocoa),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}