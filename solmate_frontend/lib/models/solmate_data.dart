class SolmateAnimal {
  final String name;
  final String normalSpritePath;

  SolmateAnimal({required this.name, required this.normalSpritePath});
}

final List<SolmateAnimal> solmateAnimals = [
  SolmateAnimal(name: "Dragon", normalSpritePath: "assets/sprites/dragon_normal.png"),
  SolmateAnimal(name: "Toly", normalSpritePath: "assets/sprites/toly_normal.png"),
  SolmateAnimal(name: "Nessie", normalSpritePath: "assets/sprites/nessie_normal.png"),
];