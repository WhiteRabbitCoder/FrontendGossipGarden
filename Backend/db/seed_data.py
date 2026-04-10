from sqlmodel import Session, select
from db.session import engine
from plant_species_profile.models import PlantSpeciesProfileModel
from plants.models import PlantsModel

def seed_data():

    with Session(engine) as session:
        species_exists = session.exec(select(PlantSpeciesProfileModel)).first()
        if not species_exists:
            print("\nInsertando Especies...\n")
            suculenta = PlantSpeciesProfileModel(
                specie_name="Suculenta",
                personality="Feliz, amable y tranquila.",
                min_temperature=15.0, max_temperature=30.0,
                min_humidity=30.0, max_humidity=50.0,
                min_soil_moisture=10.0, max_soil_moisture=30.0,
                min_light=500.0, max_light=2000.0,
                care_instructions="Riego escaso, mucha luz directa."
            )
            monstera = PlantSpeciesProfileModel(
                specie_name="Monstera",
                personality="Fuerte, activa y resistente.",
                min_temperature=18.0, max_temperature=27.0,
                min_humidity=60.0, max_humidity=80.0,
                min_soil_moisture=40.0, max_soil_moisture=70.0,
                min_light=200.0, max_light=800.0,
                care_instructions="Luz indirecta, mantener humedad alta."
            )
            session.add(suculenta)
            session.add(monstera)
            session.commit()
            session.refresh(suculenta)
            session.refresh(monstera)

            print("\nInsertanto Plantas... \n")
            planta1 = PlantsModel(
                name="Luna",
                location="Sala de estar",
                plant_species_id=suculenta.plant_species_id,
                visibility=1
            )
            planta2 = PlantsModel(
                name="Groot",
                location="Balcón",
                plant_species_id=monstera.plant_species_id,
                visibility=1
            )
            session.add(planta1)
            session.add(planta2)
            session.commit()
