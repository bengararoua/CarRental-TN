// Importation du package Material Design de Flutter, fournissant les widgets UI de base
import 'package:flutter/material.dart';
// Importation du package pour gérer les événements clavier au niveau système
import 'package:flutter/services.dart';
// Importation du package Provider pour la gestion d'état (pattern observateur)
import 'package:provider/provider.dart';
// Importation de l'écran de réservation pour navigation ultérieure
import 'booking_screen.dart';
// Importation du provider personnalisé qui gère les données des véhicules
import '../providers/vehicles_provider.dart';

// Déclaration de la classe de l'écran des favoris, qui est un StatefulWidget car elle a un état interne
class FavoritesScreen extends StatefulWidget {
  // Constructeur constant avec une clé optionnelle (Key) passée au parent
  const FavoritesScreen({Key? key}) : super(key: key);

  // Méthode obligatoire pour créer l'état associé à ce widget
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

// Classe d'état qui gère les données et la logique de l'écran des favoris
class _FavoritesScreenState extends State<FavoritesScreen> {
  // Contrôleur pour manipuler la position de défilement de la liste/grille
  final ScrollController _scrollController = ScrollController();
  // Nœud de focus pour capter les événements clavier lorsque ce widget est focalisé
  final FocusNode _focusNode = FocusNode();

  // Méthode appelée avant la destruction du widget, pour libérer les ressources
  @override
  void dispose() {
    // Détruit le contrôleur de défilement pour éviter les fuites de mémoire
    _scrollController.dispose();
    // Détache le nœud de focus pour libérer les ressources système
    _focusNode.dispose();
    // Appelle la méthode dispose de la classe parente
    super.dispose();
  }

  // Fonction pour faire défiler la liste vers le haut d'une quantité fixe
  void _scrollUp() {
    // Vérifie si le contrôleur est attaché à un widget rendu (pour éviter les erreurs)
    if (_scrollController.hasClients) {
      // Anime le défilement pour un mouvement fluide
      _scrollController.animateTo(
        // Calcule la nouvelle position : position actuelle moins 150 pixels
        _scrollController.offset - 150,
        // Durée de l'animation : 200 millisecondes
        duration: const Duration(milliseconds: 200),
        // Courbe d'animation pour un effet d'accélération/décélération
        curve: Curves.easeOut,
      );
    }
  }

  // Fonction pour faire défiler la liste vers le bas d'une quantité fixe
  void _scrollDown() {
    // Vérifie si le contrôleur est attaché à un widget rendu
    if (_scrollController.hasClients) {
      // Anime le défilement vers le bas
      _scrollController.animateTo(
        // Calcule la nouvelle position : position actuelle plus 150 pixels
        _scrollController.offset + 150,
        // Durée de l'animation
        duration: const Duration(milliseconds: 200),
        // Courbe d'animation
        curve: Curves.easeOut,
      );
    }
  }

  // Méthode principale qui construit l'interface utilisateur de l'écran
  @override
  Widget build(BuildContext context) {
    // Utilise Consumer pour écouter les changements dans VehiclesProvider
    return Consumer<VehiclesProvider>(
      // Fonction builder appelée chaque fois que le provider notifie un changement
      builder: (context, provider, child) {
        // Récupère la liste des véhicules marqués comme favoris depuis le provider
        final favoriteVehicles = provider.favorites;

        // Retourne la structure de base de l'écran (Scaffold)
        return Scaffold(
          // Définit la couleur de fond de l'écran en noir (#1A1A1A)
          backgroundColor: const Color(0xFF1A1A1A),
          // Barre d'application en haut de l'écran
          appBar: AppBar(
            // Couleur de fond de la barre d'application (identique au fond)
            backgroundColor: const Color(0xFF1A1A1A),
            // Supprime l'ombre sous la barre pour un look plat
            elevation: 0,
            // Désactive la flèche de retour automatique (car on la customise)
            automaticallyImplyLeading: false,
            // Titre personnalisé de la barre d'application
            title: MouseRegion(
              // Change le curseur de la souris en main (clic) au survol
              cursor: SystemMouseCursors.click,
              // Détecteur de gestes pour gérer le tap (clic)
              child: GestureDetector(
                // Au tap, revient à l'écran précédent dans la pile de navigation
                onTap: () => Navigator.pop(context),
                // Organise les éléments en ligne (Row)
                child: Row(
                  // La ligne prendra seulement la largeur nécessaire à son contenu
                  mainAxisSize: MainAxisSize.min,
                  // Enfants de la ligne : une icône et un texte
                  children: const [
                    // Icône de flèche de retour, blanche, taille 20
                    Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                    // Espace horizontal de 8 pixels entre l'icône et le texte
                    SizedBox(width: 8),
                    // Texte du titre
                    Text(
                      'Mes Favoris', // Titre affiché
                      style: TextStyle(
                        color: Colors.white, // Texte blanc
                        fontSize: 18, // Taille de police
                        fontWeight: FontWeight.bold, // Gras
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Corps de l'écran : contenu principal
          body: RawKeyboardListener(
            // Associe le nœud de focus défini précédemment
            focusNode: _focusNode,
            // Donne automatiquement le focus à ce widget quand il est construit
            autofocus: true,
            // Callback appelée à chaque événement clavier (appui ou relâchement)
            onKey: (event) {
              // Vérifie si l'événement est un appui sur une touche (pas un relâchement)
              if (event is RawKeyDownEvent) {
                // Si la touche flèche haut est pressée
                if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  // Appelle la fonction pour défiler vers le haut
                  _scrollUp();
                }
                // Si la touche flèche bas est pressée
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  // Appelle la fonction pour défiler vers le bas
                  _scrollDown();
                }
              }
            },
            // Appelle la méthode qui construit le corps en fonction des favoris
            child: _buildBody(favoriteVehicles),
          ),
        );
      },
    );
  }

  // Méthode qui construit le contenu principal en fonction de la liste des favoris
  Widget _buildBody(List<Map<String, dynamic>> favorites) {
    // Si la liste des favoris est vide, affiche un message approprié
    if (favorites.isEmpty) {
      // Utilise SingleChildScrollView pour permettre le défilement même sans contenu
      return SingleChildScrollView(
        // Associe le contrôleur de défilement pour le contrôle clavier
        controller: _scrollController,
        // Autorise toujours le défilement, même si le contenu est petit
        physics: const AlwaysScrollableScrollPhysics(),
        // Conteneur avec une hauteur définie (80% de la hauteur de l'écran)
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          // Centre son contenu verticalement
          child: const Center(
            // Colonne pour organiser les éléments verticalement
            child: Column(
              // Centre les enfants verticalement dans la colonne
              mainAxisAlignment: MainAxisAlignment.center,
              // Enfants de la colonne : icône et textes
              children: [
                // Icône de cœur vide (favoris non ajoutés)
                Icon(Icons.favorite_border, color: Colors.grey, size: 80),
                // Espace vertical de 16 pixels
                SizedBox(height: 16),
                // Message principal en gris clair
                Text(
                  'Aucun véhicule favori',
                  style: TextStyle(color: Colors.white70, fontSize: 18),
                ),
                // Espace vertical de 8 pixels
                SizedBox(height: 8),
                // Message secondaire en gris plus foncé
                Text(
                  'Ajoutez des véhicules à vos favoris ❤️',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Si la liste des favoris n'est pas vide, affiche une grille de cartes
    return GridView.builder(
      // Associe le contrôleur de défilement pour le contrôle clavier
      controller: _scrollController,
      // Marge intérieure de 16 pixels sur tous les côtés de la grille
      padding: const EdgeInsets.all(16),
      // Définit la disposition des éléments dans la grille
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        // Largeur maximale d'un élément avant de passer à la ligne suivante
        maxCrossAxisExtent: 400,
        // Hauteur fixe de chaque élément de la grille
        mainAxisExtent: 350,
        // Espace horizontal entre les éléments
        crossAxisSpacing: 16,
        // Espace vertical entre les éléments
        mainAxisSpacing: 16,
      ),
      // Nombre total d'éléments dans la grille (égal au nombre de favoris)
      itemCount: favorites.length,
      // Fonction appelée pour construire chaque élément de la grille
      itemBuilder: (context, index) =>
          // Appelle la méthode qui construit une carte pour un véhicule donné
          _buildFavoriteCard(favorites[index], context),
    );
  }

  // Méthode qui construit une carte individuelle pour un véhicule favori
  Widget _buildFavoriteCard(Map<String, dynamic> v, BuildContext context) {
    // Récupère l'état "favori" du véhicule (ici, devrait toujours être true)
    final bool isFavorite = v['isFavorite'] ?? false;

    // Retourne un conteneur qui sert de carte pour le véhicule
    return Container(
      // Décoration de la carte : fond arrondi et couleur
      decoration: BoxDecoration(
        // Couleur de fond gris foncé (#2A2A2A)
        color: const Color(0xFF2A2A2A),
        // Coins arrondis avec un rayon de 16 pixels
        borderRadius: BorderRadius.circular(16),
      ),
      // Colonne pour organiser le contenu de la carte verticalement
      child: Column(
        // Aligne les enfants au début de l'axe transversal (à gauche)
        crossAxisAlignment: CrossAxisAlignment.start,
        // Enfants de la colonne : image, détails, bouton
        children: [
          // Stack permet de superposer des widgets (image + bouton favori)
          Stack(
            children: [
              // Widget pour découper l'image avec des bords arrondis
              ClipRRect(
                // Arrondit seulement les coins supérieurs de l'image
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                // Image chargée depuis le réseau (URL)
                child: Image.network(
                  // URL de l'image du véhicule, extraite des données
                  v['image'],
                  // Remplit l'espace disponible sans déformer l'image
                  fit: BoxFit.cover,
                  // Prend toute la largeur disponible
                  width: double.infinity,
                  // Hauteur fixe de 160 pixels
                  height: 160,
                  // Builder appelé en cas d'erreur de chargement de l'image
                  errorBuilder: (_, __, ___) => Container(
                    // Conteneur de remplacement avec la même hauteur
                    height: 160,
                    // Couleur de fond de secours (gris plus clair)
                    color: const Color(0xFF3A3A3A),
                    // Centre une icône dans le conteneur
                    child: const Center(
                      // Icône de voiture (représentation générique)
                      child: Icon(Icons.car_repair, color: Colors.white),
                    ),
                  ),
                ),
              ),

              // Bouton pour retirer le véhicule des favoris, positionné en haut à droite
              Positioned(
                // Position verticale : 8 pixels du bord supérieur
                top: 8,
                // Position horizontale : 8 pixels du bord droit
                right: 8,
                // Détecteur de gestes pour gérer le tap sur le bouton
                child: GestureDetector(
                  // Callback appelée quand on appuie sur le bouton cœur
                  onTap: () {
                    // Appelle la méthode toggleFavorite du provider pour basculer l'état
                    // listen: false car on ne veut pas réécouter le provider ici (pas de rebuild immédiat)
                    Provider.of<VehiclesProvider>(context, listen: false)
                        .toggleFavorite(v['id'] ?? 0);
                  },
                  // Conteneur rond pour le bouton cœur
                  child: Container(
                    // Marge intérieure de 6 pixels tout autour
                    padding: const EdgeInsets.all(6),
                    // Décoration du bouton : cercle avec fond semi-transparent
                    decoration: BoxDecoration(
                      // Fond noir avec 40% d'opacité
                      color: Colors.black.withOpacity(0.4),
                      // Forme circulaire
                      shape: BoxShape.circle,
                    ),
                    // Icône cœur, pleine ou vide selon l'état
                    child: Icon(
                      // Si favori, cœur plein, sinon cœur vide
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      // Couleur rouge si favori, blanc sinon
                      color: isFavorite ? Colors.red : Colors.white,
                      // Taille de l'icône
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Widget qui prend l'espace restant dans la colonne
          Expanded(
            child: Padding(
              // Marge intérieure de 12 pixels sur tous les côtés
              padding: const EdgeInsets.all(12),
              // Colonne pour les détails textuels du véhicule
              child: Column(
                // Aligne le texte à gauche
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom du véhicule
                  Text(
                    // Nom extrait des données
                    v['name'],
                    style: const TextStyle(
                      color: Colors.white, // Texte blanc
                      fontSize: 15, // Taille moyenne
                      fontWeight: FontWeight.bold, // Gras
                    ),
                    // Limite à une seule ligne
                    maxLines: 1,
                    // Affiche "..." si le texte dépasse
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Catégorie du véhicule (ex: SUV, Sport)
                  Text(
                    v['category'],
                    style: const TextStyle(color: Colors.blue, fontSize: 11),
                  ),
                  // Espace vertical de 4 pixels
                  const SizedBox(height: 4),
                  // Prend l'espace restant pour la description
                  Expanded(
                    child: SingleChildScrollView(
                      // Permet de défiler la description si elle est trop longue
                      child: Text(
                        // Description générée dynamiquement à partir des données
                        "Cette voiture (${v['year']}) avec moteur ${v['engine']} "
                        "offre ${v['seats']} places et une boîte ${v['transmission']}. "
                        "Carburant: ${v['fuel']}. Coffre: ${v['luggage']} bagages. "
                        "${v['airConditioning'] ? 'Climatisée.' : 'Non climatisée.'}",
                        style: const TextStyle(
                          color: Colors.white70, // Gris clair
                          fontSize: 11, // Petite taille
                          height: 1.3, // Interligne
                        ),
                      ),
                    ),
                  ),
                  // Espace vertical de 4 pixels
                  const SizedBox(height: 4),
                  // Ligne pour le prix et le bouton de réservation
                  Row(
                    // Répartit l'espace entre le prix (à gauche) et le bouton (à droite)
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prix du véhicule
                      Text(
                        // Convertit le prix en entier et ajoute " TND"
                        "${v['price'].toInt()} TND",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // Bouton pour réserver le véhicule
                      ElevatedButton(
                        // Style personnalisé du bouton
                        style: ElevatedButton.styleFrom(
                          // Couleur de fond : blanc si disponible, gris foncé sinon
                          backgroundColor: v['isAvailable']
                              ? Colors.white
                              : Colors.grey[800],
                          // Couleur du texte : noir si disponible, gris clair sinon
                          foregroundColor: v['isAvailable']
                              ? Colors.black
                              : Colors.white38,
                          // Forme du bouton : bords arrondis comme un stade
                          shape: const StadiumBorder(),
                          // Marge horizontale à l'intérieur du bouton
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        // Callback : active seulement si le véhicule est disponible
                        onPressed: v['isAvailable']
                            ? () {
                                // Navigation vers l'écran de réservation
                                Navigator.push(
                                  context,
                                  // Crée une route vers BookingScreen avec les données du véhicule
                                  MaterialPageRoute(
                                    builder: (_) => BookingScreen(vehicle: v),
                                  ),
                                );
                              }
                            : null, // Désactive le bouton si non disponible
                        // Texte du bouton : "Réserver" ou "Occupé"
                        child: Text(
                          v['isAvailable'] ? "Réserver" : "Occupé",
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}