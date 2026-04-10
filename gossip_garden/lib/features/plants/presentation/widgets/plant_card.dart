// presentation/widgets/plant_card.dart
Widget buildPlantCard(Plant plant) {
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Colors.grey.shade200),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildPlantAvatar(plant), // Un círculo con la imagen o icono
          const SizedBox(width: 16),
          Expanded(child: _buildPlantInfo(plant)),
          _buildHealthBadge(plant), // Usando la lógica de tus badges
        ],
      ),
    ),
  );
}