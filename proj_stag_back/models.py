# ============================================================
# MODÈLES DE BASE DE DONNÉES - APPLICATION DE GESTION DE VÉHICULES
# ============================================================

from sqlalchemy import create_engine, Column, Integer, String, Boolean, Float, ForeignKey, TIMESTAMP, DateTime, Text, Date, DECIMAL
from sqlalchemy.orm import sessionmaker, declarative_base, relationship
from datetime import datetime

# ============================================================
# CONFIGURATION DE LA CONNEXION À LA BASE DE DONNÉES
# ============================================================

URL_DATABASE = "mysql+pymysql://root:@localhost:3306/gest_app1"

engine = create_engine(URL_DATABASE, echo=True)

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
    created_at = Column(DateTime, default=datetime.now)
    
    favorites = relationship("Favorite", back_populates="user")
    bookings = relationship("Booking", back_populates="user", foreign_keys="Booking.user_id")
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
    created_at = Column(DateTime, default=datetime.now)
    
    # Relation vers la table 'User' : permet d'accéder à toutes les infos de l'utilisateur
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
    created_at = Column(DateTime, default=datetime.now)
    
    user = relationship("User", back_populates="favorites")
    car = relationship("vehicles", back_populates="favorites")

# ============================================================
# MODÈLE RÉSERVATION (TABLE "bookings")
# ============================================================

class Booking(Base):
    __tablename__ = 'bookings'
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    car_id = Column(Integer, ForeignKey("cars.id", ondelete="CASCADE"), nullable=False)
    full_name = Column(String(100), nullable=False)
    pickup_date = Column(Date, nullable=False)
    return_date = Column(Date, nullable=False)
    total_price = Column(Float, nullable=False)
    status = Column(String(20), default='En attente')
    created_at = Column(DateTime, default=datetime.utcnow)

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
    created_at = Column(DateTime, default=datetime.now)
    updated_at = Column(DateTime, default=datetime.now, onupdate=datetime.now)
    is_active = Column(Boolean, default=True)
    
    user = relationship("User", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan", order_by="Message.created_at")

class Message(Base):
    __tablename__ = "messages"
    
    id = Column(Integer, primary_key=True, index=True)
    conversation_id = Column(Integer, ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    content = Column(Text, nullable=False)
    is_user = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.now)
    
    conversation = relationship("Conversation", back_populates="messages")

# ============================================================
# CRÉATION DES TABLES DANS LA BASE DE DONNÉES
# ============================================================

Base.metadata.create_all(bind=engine)