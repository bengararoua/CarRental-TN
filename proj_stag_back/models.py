# ============================================================
# MODÈLES DE BASE DE DONNÉES - APPLICATION DE GESTION DE VÉHICULES
# ============================================================
# SQLAlchemy : bibliothèque Python qui permet de manipuler une base de données en utilisant du code Python (ORM) au lieu d’écrire directement du SQL.
#ORM = technique qui permet de manipuler une base de données avec du code Python au lieu du SQL
# create_engine : fonction de SQLAlchemy qui permet de créer la connexion entre application Python et la base de données.
from sqlalchemy import create_engine, Column, Integer, String, Boolean, Float, ForeignKey, TIMESTAMP, DateTime, Text, Date, DECIMAL
# sqlalchemy.orm : module de SQLAlchemy qui contient les outils de l’ORM
# sessionmaker : permet de créer des sessions pour interagir avec la base de données.
# DeclarativeBase : classe de base utilisée pour définir les modèles (tables) sous forme de classes Python
# relationship : permet de définir les relations entre les tables
from sqlalchemy.orm import sessionmaker, declarative_base, relationship
from datetime import datetime

# ============================================================
# CONFIGURATION DE LA CONNEXION À LA BASE DE DONNÉES
# ============================================================

URL_DATABASE = "mysql+pymysql://root:@localhost:3306/gest_app1"
# echo=True : permet d’afficher dans la console toutes les requêtes SQL générées
engine = create_engine(URL_DATABASE, echo=True)
# autocommit=False : les modifications ne sont pas enregistrées automatiquement.
#autoflush=False : empêche l’envoi automatique des modifications à la base
# bind=engine : lie la session au moteur de base de données (engine),
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

# ============================================================
# MODÈLE UTILISATEUR (TABLE "users")
# ============================================================

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), nullable=False)
    email = Column(String(100), unique=True, index=True, nullable=False)
    hashed_password = Column(String(255), nullable=False)
    # Rôle de l'utilisateur : 'user' pour les clients normaux, 'admin' pour les administrateurs
    role = Column(String(20), default="user")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    # "Favorite" est le nom de la classe (modèle) liée à cette relation.
    # back_populates="user" : permet de créer une liaison bidirectionnelle:Depuis User, on peut accéder aux favorites Et depuis chaque Favorite, on peut retrouver son user
    favorites = relationship("Favorite", back_populates="user")
    bookings = relationship("Booking", back_populates="user", foreign_keys="Booking.user_id")
    # cascade="all":permet de propager automatiquement toutes les opérations effectuées sur l’objet parent vers les objets liés (enfants).
    # delete-orphan :supprime automatiquement les objets qui ne sont plus liés à leur parent.
    conversations = relationship("Conversation", back_populates="user", cascade="all, delete-orphan")

# ============================================================
# MODÈLE ADMINISTRATEUR (TABLE "admins")
# ============================================================
# Ce tableau contient les utilisateurs qui ont le rôle 'admin'.
# Un admin est d'abord créé dans la table 'users' avec role='admin',
# puis une copie COMPLÈTE de ses informations est insérée ici dans 'admins'.
# La table admins a exactement les mêmes attributs que la table users,

class Admin(Base):
    # Nom de la table dans la base de données
    __tablename__ = "admins"
    
    # Identifiant unique pour chaque enregistrement dans la table admins
    # C'est l'identifiant propre à cette table (différent de l'id dans users)
    id = Column(Integer, primary_key=True, index=True)
    
    # Référence à l'ID de l'utilisateur correspondant dans la table 'users'
    # Permet de lier l'admin à son compte utilisateur principal
    # ondelete="CASCADE": si l'utilisateur est supprimé de 'users', il est aussi supprimé d'ici
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, unique=True)
    
    # -------------------------------------------------------
    # MÊMES ATTRIBUTS QUE LA TABLE "users"
    # -------------------------------------------------------
    
    # Nom d'utilisateur (copié depuis users.username)
    username = Column(String(50), nullable=False)
    
    # Adresse email (copiée depuis users.email), doit être unique
    email = Column(String(100), nullable=False, unique=True)
    
    # Mot de passe haché (copié depuis users.hashed_password)
    # Même valeur que dans users pour que l'admin puisse se connecter via les deux tables
    hashed_password = Column(String(255), nullable=False)
    
    # Rôle de l'admin (toujours 'admin' dans cette table)
    # Copié depuis users.role
    role = Column(String(20), default="admin")
    
    # Indique si le compte admin est actif (copié depuis users.is_active)
    # True = actif, False = désactivé
    is_active = Column(Boolean, default=True)
    
    # Date de création du compte (copiée depuis users.created_at)
    # utilisation de datetime.utcnow (cohérent avec tous les autres modèles)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    # Relation vers la table 'User' : permet d'accéder à toutes les infos de l'utilisateur
    # backref="admin_profile":ajoute automatiquement un attribut "admin_profile" dans la classe User .Grâce à ça, on peut accéder à l’admin directement depuis un user.
    user = relationship("User", backref="admin_profile")

# ============================================================
# MODÈLE VÉHICULE (TABLE "cars")
# ============================================================

class vehicles(Base):
    __tablename__ = "cars"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    category = Column(String(50), nullable=False)
    price = Column(DECIMAL(10,2), nullable=False)
    image = Column(String(500), nullable=False)
    transmission = Column(String(50))
    seats = Column(Integer)
    engine = Column(String(50))
    year = Column(Integer)
    fuel = Column(String(50))
    isAvailable = Column(Boolean, default=True)
    isNew = Column(Boolean, default=False)
    isBestChoice = Column(Boolean, default=False)
    rating = Column(DECIMAL(3,1), default=0.0)
    popularity = Column(String(50), default='')
    luggage = Column(String(20), default='')
    airConditioning = Column(Boolean, default=True)
    bluetooth = Column(Boolean, default=True)
    
    favorites = relationship("Favorite", back_populates="car")
    bookings = relationship("Booking", back_populates="car", foreign_keys="Booking.car_id")

# ============================================================
# MODÈLE FAVORI (TABLE "favorites")
# ============================================================

class Favorite(Base):
    __tablename__ = "favorites"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    car_id = Column(Integer, ForeignKey("cars.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    user = relationship("User", back_populates="favorites")
    car = relationship("vehicles", back_populates="favorites")

# ============================================================
# MODÈLE RÉSERVATION (TABLE "bookings")
# ============================================================

class Booking(Base):
    __tablename__ = 'bookings'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    ## ondelete="CASCADE" : si un utilisateur est supprimé,tous les enregistrements liés sont supprimé ainsi
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    car_id = Column(Integer, ForeignKey("cars.id", ondelete="CASCADE"), nullable=False)
    full_name = Column(String(100), nullable=False)
    pickup_date = Column(Date, nullable=False)
    return_date = Column(Date, nullable=False)
    total_price = Column(Float, nullable=False)
    status = Column(String(20), default='En attente')
    created_at = Column(DateTime, default=datetime.utcnow)
#[car_id]:liste des ids des vehicules
    car = relationship("vehicles", back_populates="bookings", foreign_keys=[car_id])
    user = relationship("User", back_populates="bookings", foreign_keys=[user_id])

# ============================================================
# MODÈLES POUR LES CONVERSATIONS (SYSTÈME DE CHAT)
# ============================================================

class Conversation(Base):
    __tablename__ = "conversations"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), default="Nouvelle conversation")
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    is_active = Column(Boolean, default=True)
    
    user = relationship("User", back_populates="conversations")
    #order_by="Message.created_at":tri par "Message.created_at"
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan", order_by="Message.created_at")

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    content = Column(Text, nullable=False)
    is_user = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    
    conversation = relationship("Conversation", back_populates="messages")

# ============================================================
# CRÉATION DES TABLES DANS LA BASE DE DONNÉES
# ============================================================

Base.metadata.create_all(bind=engine)