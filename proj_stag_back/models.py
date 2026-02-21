# ============================================================
# MODÈLES DE BASE DE DONNÉES - APPLICATION DE GESTION DE VÉHICULES
# ============================================================

# Importer les modules nécessaires de SQLAlchemy pour définir les modèles de base de données
# ORM (Object-Relational Mapping) qui permet de manipuler la base de données avec des objets Python
#timestamp est une valeur qui indique la date et l’heure exactes d’un événement
#datetime est un type de donnée qui représente directement une date et une heure sous un format lisible
from sqlalchemy import create_engine, Column, Integer, String, Boolean, Float, ForeignKey, TIMESTAMP, DateTime, Text, Date, DECIMAL

# Importer les utilitaires de SQLAlchemy pour créer des sessions, définir des classes de modèle et gérer les relations
# sessionmaker: fabrique pour créer des sessions de base de données
# declarative_base: base pour créer des classes de modèle en style déclaratif
# relationship: permet de définir des relations entre tables 
from sqlalchemy.orm import sessionmaker, declarative_base, relationship

# Importer le module datetime pour gérer les dates et heures
# Utilisé pour les colonnes de type DateTime et Date
from datetime import datetime

# ============================================================
# CONFIGURATION DE LA CONNEXION À LA BASE DE DONNÉES
# ============================================================

# Définir l'URL de connexion à la base de données MySQL avec les paramètres d'authentification
# Format: mysql+pymysql://utilisateur:motdepasse@hôte:port/nom_de_la_base
# Ici: utilisateur=root, pas de mot de passe, localhost sur le port 3306, base de données nommée "gest_app1"
URL_DATABASE = "mysql+pymysql://root:@localhost:3306/gest_app1"

# Créer un moteur de base de données SQLAlchemy avec l'URL définie et activer l'écho pour voir les requêtes SQL
# Le moteur est l'interface principale avec la base de données
# echo=True affiche toutes les requêtes SQL générées dans le terminal (utile pour le débogage)
engine = create_engine(URL_DATABASE, echo=True)

# Créer une classe de session locale configurée avec les paramètres de non auto-commit et non auto-flush, liée au moteur
# SessionLocal pour créer des instances de session
# autocommit=False: les modifications ne sont pas automatiquement validées
# autoflush=False: pas de synchronisation automatique entre les objets Python et la base de données
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Créer une classe de base pour toutes les classes de modèle (déclarative style)
# Toutes les classes de modèle hériteront de cette classe Base
Base = declarative_base()

# ============================================================
# MODÈLE UTILISATEUR (TABLE "users")
# ============================================================

# Définir la classe modèle pour la table "users" représentant les utilisateurs de l'application
class User(Base):
    # Spécifier le nom de la table dans la base de données
    # SQLAlchemy utilisera ce nom pour créer la table et exécuter les requêtes
    __tablename__ = "users"
    
    # Définir la colonne ID comme clé primaire avec un index pour des recherches rapides
    # Integer: type entier, primary_key=True: clé primaire, index=True: crée un index pour optimiser les recherches
    id = Column(Integer, primary_key=True, index=True)
    
    # Colonne pour le nom d'utilisateur, ne peut pas être nulle, avec une longueur maximale de 50 caractères
    # String(50): type chaîne de caractères avec limite de 50 caractères
    # nullable=False: la colonne ne peut pas contenir de valeur NULL
    username = Column(String(50), nullable=False)
    
    # Colonne pour l'email, unique et indexée pour éviter les doublons et optimiser les recherches
    # unique=True: garantit qu'aucune autre ligne n'aura la même valeur
    # index=True: crée un index pour accélérer les recherches par email
    # nullable=False: l'email est obligatoire
    email = Column(String(100), unique=True, index=True, nullable=False)
    
    # Colonne pour stocker le mot de passe haché (sécurité)
    # String(255): type chaîne avec limite de 255 caractères 
    # nullable=False: le mot de passe est obligatoire
    hashed_password = Column(String(255), nullable=False)
    
    # Colonne pour le rôle de l'utilisateur (par défaut "user"), longueur maximale 20 caractères
    # default="user": valeur par défaut 
    # Permet de gérer les permissions (admin, user, etc.)
    role = Column(String(20), default="user")
    
    # Colonne booléenne pour indiquer si le compte est actif (par défaut True)
    # Boolean: type booléen (True/False)
    # default=True: par défaut, un nouveau compte est actif
    is_active = Column(Boolean, default=True)
    
    # Colonne pour la date de création du compte, valeur par défaut = date/heure actuelle
    # DateTime: type date et heure
    # default=datetime.now: fonction appelée pour définir la valeur par défaut au moment de la création
    created_at = Column(DateTime, default=datetime.now)
    
    # Relations : définir la relation avec la table "favorites" (un utilisateur peut avoir plusieurs favoris)
    # relationship: crée une relation 
    # "Favorite": nom de la classe cible de la relation
    # back_populates="user": crée une relation bidirectionnelle (la classe Favorite aura un attribut "user")
    favorites = relationship("Favorite", back_populates="user")
    
    # Relation avec la table "bookings" (un utilisateur peut avoir plusieurs réservations)
    # foreign_keys="Booking.user_id": spécifie explicitement la clé étrangère pour éviter les ambiguïtés
    bookings = relationship("Booking", back_populates="user", foreign_keys="Booking.user_id")
    
    # Relation avec la table "conversations" (un utilisateur peut avoir plusieurs conversations)
    # cascade="all, delete-orphan": si l'utilisateur est supprimé, ses conversations sont aussi supprimées
    conversations = relationship("Conversation", back_populates="user", cascade="all, delete-orphan")

# ============================================================
# MODÈLE VÉHICULE (TABLE "cars")
# ============================================================

# Définir la classe modèle pour la table "cars" représentant les véhicules disponibles à la location
class vehicles(Base):
    # Cette table s'appelle "cars" dans la base de données
    __tablename__ = "cars"
    
    # Définir la colonne ID comme clé primaire avec un index
    # Identifiant unique pour chaque véhicule
    id = Column(Integer, primary_key=True, index=True)
    
    # Colonne pour le nom du véhicule, ne peut pas être nulle
    # Exemple: "Toyota Camry", "BMW X5"
    name = Column(String(100), nullable=False)
    
    # Colonne pour la catégorie du véhicule (ex: SUV, berline, compact, etc.)
    category = Column(String(50), nullable=False)
    
    # Colonne pour le prix de location par jour (DECIMAL pour correspondre à la base de données)
    # DECIMAL(10,2): nombre décimal avec 10 chiffres au total dont 2 après la virgule
    price = Column(DECIMAL(10,2), nullable=False)
    
    # Colonne pour l'URL de l'image du véhicule (longueur max 500 caractères)
    image = Column(String(500), nullable=False)
    
    # Colonne pour le type de transmission (manuel/automatique)
    transmission = Column(String(50))
    
    # Colonne pour le nombre de sièges
    # Integer: type entier
    seats = Column(Integer)
    
    # Colonne pour le type de moteur (ex: essence, diesel, hybride, électrique)
    engine = Column(String(50))
    
    # Colonne pour l'année de fabrication du véhicule
    year = Column(Integer)
    
    # Colonne pour le type de carburant (ex: essence, diesel, électrique)
    fuel = Column(String(50))
    
    # Colonne booléenne pour indiquer la disponibilité (par défaut True)
    # True = disponible à la location, False = déjà loué ou en maintenance
    isAvailable = Column(Boolean, default=True)
    
    # Colonne booléenne pour indiquer si le véhicule est récent (par défaut False)
    isNew = Column(Boolean, default=False)
    
    # Colonne booléenne pour indiquer si c'est un choix recommandé (par défaut False)
    isBestChoice = Column(Boolean, default=False)
    
    # Colonne pour la note moyenne (DECIMAL(3,1) pour correspondre à la base de données)
    rating = Column(DECIMAL(3,1), default=0.0)
    
    # Colonne pour la popularité (varchar(50) pour correspondre à la base de données)
    # Peut contenir des valeurs comme "Élevée", "Moyenne", "Faible"
    popularity = Column(String(50), default='')
    
    # Colonne pour la capacité du coffre (varchar(20) pour correspondre à la base de données)
    # Exemple: "500L", "Grand coffre"
    luggage = Column(String(20), default='')
    
    # Colonne booléenne pour indiquer la présence de la climatisation (par défaut True)
    airConditioning = Column(Boolean, default=True)
    
    # Colonne booléenne pour indiquer la présence du Bluetooth (par défaut True)
    bluetooth = Column(Boolean, default=True)
    
    # Relations : relation avec la table "favorites" (une voiture peut être dans plusieurs favoris)
    # Un véhicule peut être ajouté aux favoris par plusieurs utilisateurs
    favorites = relationship("Favorite", back_populates="car")
    
    # Relation avec la table "bookings" (une voiture peut avoir plusieurs réservations)
    # Un véhicule peut être réservé plusieurs fois (à des dates différentes)
    bookings = relationship("Booking", back_populates="car", foreign_keys="Booking.car_id")

# ============================================================
# MODÈLE FAVORI (TABLE "favorites")
# ============================================================

# Définir la classe modèle pour la table "favorites" représentant les favoris des utilisateurs
class Favorite(Base):
    # Spécifier le nom de la table dans la base de données
    __tablename__ = "favorites"
    
    # Définir la colonne ID comme clé primaire avec un index
    # Identifiant unique pour chaque enregistrement de favori
    id = Column(Integer, primary_key=True, index=True)
    
    # Clé étrangère vers la table "users", ne peut pas être nulle
    # ForeignKey("users.id"): fait référence à la colonne id de la table users
    # nullable=False: un favori doit toujours être associé à un utilisateur
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    
    # Clé étrangère vers la table "cars", ne peut pas être nulle
    # ForeignKey("cars.id"): fait référence à la colonne id de la table cars
    # nullable=False: un favori doit toujours être associé à un véhicule
    car_id = Column(Integer, ForeignKey("cars.id"), nullable=False)
    
    # Colonne pour la date de création du favori, valeur par défaut = date/heure actuelle
    # Permet de savoir quand l'utilisateur a ajouté ce véhicule à ses favoris
    created_at = Column(DateTime, default=datetime.now)
    
    # Relations : relation vers la table "User" avec rétro-référence via le champ "favorites"
    # back_populates="favorites": crée un attribut "favorites" dans la classe User
    user = relationship("User", back_populates="favorites")
    
    # Relation vers la table "vehicles" (voiture) avec rétro-référence via le champ "favorites"
    # back_populates="favorites": crée un attribut "favorites" dans la classe vehicles
    #back_populates permet de créer un lien bidirectionnel entre deux tables
    car = relationship("vehicles", back_populates="favorites")

# ============================================================
# MODÈLE RÉSERVATION (TABLE "bookings")
# ============================================================

# Définir la classe modèle pour la table "bookings" représentant les réservations de véhicules
class Booking(Base):
    # Spécifier le nom de la table dans la base de données
    __tablename__ = 'bookings'
    
    # Définir la colonne ID comme clé primaire avec auto-incrémentation
    # autoincrement=True: la valeur s'incrémente automatiquement à chaque nouvel enregistrement
    id = Column(Integer, primary_key=True, autoincrement=True)
    
    # Clé étrangère vers "users" avec suppression en cascade, ne peut pas être nulle
    # ondelete="CASCADE": si l'utilisateur est supprimé, ses réservations sont aussi supprimées
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # Clé étrangère vers "cars" avec suppression en cascade, ne peut pas être nulle
    # ondelete="CASCADE": si le véhicule est supprimé, ses réservations sont aussi supprimées
    car_id = Column(Integer, ForeignKey("cars.id", ondelete="CASCADE"), nullable=False)
    
    # Colonne pour le nom complet de la personne qui fait la réservation
    # Peut être différent du nom d'utilisateur (ex: réservation pour un tiers)
    full_name = Column(String(100), nullable=False)
    
    # Colonne pour la date de prise en charge du véhicule (type Date)
    # Date: type date sans heure
    pickup_date = Column(Date, nullable=False)
    
    # Colonne pour la date de retour du véhicule (type Date)
    return_date = Column(Date, nullable=False)
    
    # Colonne pour le prix total de la réservation (flottant)
    # Float: nombre à virgule flottante
    # Calculé en fonction du prix journalier et de la durée
    total_price = Column(Float, nullable=False)
    
    # Colonne pour le statut de la réservation (par défaut "En attente")
    # Peut être: "En attente", "Confirmée", "Annulée", "Terminée"
    status = Column(String(20), default='En attente')
    
    # Colonne pour la date de création de la réservation, valeur par défaut = date/heure UTC actuelle
    # datetime.utcnow: utilise le temps universel coordonné (UTC) pour être indépendant du fuseau horaire
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relations : relation vers la table "vehicles" (voiture) avec rétro-référence via le champ "bookings"
    # foreign_keys=[car_id]: spécifie explicitement quelle colonne est utilisée pour la relation
    car = relationship("vehicles", back_populates="bookings", foreign_keys=[car_id])
    
    # Relation vers la table "User" avec rétro-référence via le champ "bookings"
    # foreign_keys=[user_id]: spécifie explicitement quelle colonne est utilisée pour la relation
    user = relationship("User", back_populates="bookings", foreign_keys=[user_id])

# ============================================================
#MODÈLES POUR LES CONVERSATIONS (SYSTÈME DE CHAT)
# ============================================================

# Définir la classe modèle pour la table "conversations" représentant les conversations de l'assistant
class Conversation(Base):
    # Spécifier le nom de la table dans la base de données
    __tablename__ = "conversations"
    
    # Définir la colonne ID comme clé primaire avec un index
    id = Column(Integer, primary_key=True, index=True)
    
    # Clé étrangère vers la table "users", ne peut pas être nulle
    # ondelete="CASCADE": si l'utilisateur est supprimé, ses conversations sont aussi supprimées
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    
    # Colonne pour le titre de la conversation (par défaut "Nouvelle conversation")
    # Permet à l'utilisateur d'identifier ses conversations
    title = Column(String(255), default="Nouvelle conversation")
    
    # Colonne pour la date de création, valeur par défaut = date/heure actuelle
    created_at = Column(DateTime, default=datetime.now)
    
    # Colonne pour la date de dernière mise à jour, mise à jour automatiquement
    # onupdate=datetime.now: met automatiquement à jour avec la date/heure actuelle à chaque modification
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    
    # Colonne booléenne pour indiquer si la conversation est active (par défaut True)
    # Permet d'archiver des conversations sans les supprimer
    is_active = Column(Boolean, default=True)
    
    # Relations : relation vers la table "User" avec rétro-référence via le champ "conversations"
    user = relationship("User", back_populates="conversations")
    
    # Relation avec la table "messages" (une conversation peut avoir plusieurs messages)
    # cascade="all, delete-orphan": si la conversation est supprimée, tous ses messages sont supprimés
    # order_by="Message.created_at": les messages sont triés par date de création (du plus ancien au plus récent)
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan", order_by="Message.created_at")

# Définir la classe modèle pour la table "messages" représentant les messages d'une conversation
class Message(Base):
    # Spécifier le nom de la table dans la base de données
    __tablename__ = "messages"
    
    # Définir la colonne ID comme clé primaire avec un index
    id = Column(Integer, primary_key=True, index=True)
    
    # Clé étrangère vers la table "conversations", ne peut pas être nulle
    # ondelete="CASCADE": si la conversation est supprimée, tous ses messages sont supprimés
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    
    # Colonne pour le contenu du message (texte)
    # Text: type texte long (pas de limite de longueur prédéfinie contrairement à String)
    content = Column(Text, nullable=False)
    
    # Colonne booléenne pour indiquer si le message vient de l'utilisateur (True) ou de l'assistant (False)
    # True = message envoyé par l'utilisateur
    # False = message envoyé par l'assistant (réponse)
    is_user = Column(Boolean, default=True)
    
    # Colonne pour la date de création du message, valeur par défaut = date/heure actuelle
    created_at = Column(DateTime, default=datetime.now)
    
    # Relations : relation vers la table "Conversation" avec rétro-référence via le champ "messages"
    conversation = relationship("Conversation", back_populates="messages")

# ============================================================
# CRÉATION DES TABLES DANS LA BASE DE DONNÉES
# ============================================================

# Créer toutes les tables définies dans les modèles dans la base de données (si elles n'existent pas déjà)
# create_all: génère les commandes SQL CREATE TABLE pour toutes les tables non existantes
# bind=engine: utilise le moteur de base de données configuré précédemment pour exécuter les commandes
Base.metadata.create_all(bind=engine)
