import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// 地图选址（OpenStreetMap，免费无需 Key）。
/// 在地图上点一下放置标记，可给地点取名；确定后返回一段地址文本。
///
/// 返回值：地点名（若填写）否则「纬度,经度」。
class LocationPickerPage extends StatefulWidget {
  const LocationPickerPage({super.key, this.initialText});

  final String? initialText;

  @override
  State<LocationPickerPage> createState() => _LocationPickerPageState();
}

class _LocationPickerPageState extends State<LocationPickerPage> {
  // 默认视角：中国大致中心；用户点选后再定位。
  static const LatLng _fallback = LatLng(34.34, 108.94);

  final _nameController = TextEditingController();
  LatLng? _picked;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialText ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      Navigator.of(context).pop(name);
      return;
    }
    if (_picked != null) {
      final s =
          '${_picked!.latitude.toStringAsFixed(5)},${_picked!.longitude.toStringAsFixed(5)}';
      Navigator.of(context).pop(s);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('请在地图上点选一个位置或填写地点名')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('选择地址'),
        actions: [
          TextButton(onPressed: _confirm, child: const Text('确定')),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _fallback,
                initialZoom: 4,
                onTap: (tapPos, latlng) => setState(() => _picked = latlng),
              ),
              children: [
                TileLayer(
                  // 高德地图瓦片：国内可访问、免费。style=7 为标准地图。
                  urlTemplate:
                      'https://wprd0{s}.is.autonavi.com/appmaptile?x={x}&y={y}&z={z}&lang=zh_cn&size=1&scl=1&style=7',
                  subdomains: const ['1', '2', '3', '4'],
                  userAgentPackageName: 'com.photomaster.photomaster',
                ),
                if (_picked != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _picked!,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.location_on,
                            color: Theme.of(context).colorScheme.error,
                            size: 40),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_picked != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '已选：${_picked!.latitude.toStringAsFixed(5)}, ${_picked!.longitude.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '地点名（可选）',
                    hintText: '如：西湖 · 断桥',
                    prefixIcon: Icon(Icons.place_outlined),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
