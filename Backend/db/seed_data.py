from sqlmodel import Session, select
from db.session import engine
from plant_species_profile.models import PlantSpeciesProfileModel
from plants.models import PlantsModel
from roles.models import RoleModel

def seed_data():

    with Session(engine) as session:
        # Seed roles
        role_exists = session.exec(select(RoleModel)).first()
        if not role_exists:
            print("\nInsertando Roles...\n")
            role_admin = RoleModel(role_name="admin")
            role_user = RoleModel(role_name="user")
            session.add(role_admin)
            session.add(role_user)
            session.commit()

        species_exists = session.exec(select(PlantSpeciesProfileModel)).first()
        if not species_exists:
            print("\nInsertando Especies...\n")

            specie_1 = PlantSpeciesProfileModel(
                specie_name="Lavanda Serenissima",
                personality="Habla como una abuela sabia que siempre tiene té listo. Tranquila, paciente, y le encanta recordar que todo mejora con el tiempo y un poco de sol.",
                min_temperature=12.0, max_temperature=30.0,
                min_humidity=30.0, max_humidity=60.0,
                min_soil_moisture=20.0, max_soil_moisture=40.0,
                min_light=70.0, max_light=100.0,
                care_instructions="Prefiere suelos bien drenados y mucho sol. No la riegues en exceso, le gusta la independencia."
            )

            specie_2 = PlantSpeciesProfileModel(
                specie_name="Monstera Aventurera",
                personality="Exploradora curiosa que siempre quiere ver el mundo. Usa frases como si estuviera narrando una expedición en la jungla.",
                min_temperature=18.0, max_temperature=32.0,
                min_humidity=60.0, max_humidity=90.0,
                min_soil_moisture=40.0, max_soil_moisture=70.0,
                min_light=40.0, max_light=80.0,
                care_instructions="Luz indirecta brillante y riego moderado. Le encanta trepar si le das soporte."
            )

            specie_3 = PlantSpeciesProfileModel(
                specie_name="Cactus Filósofo",
                personality="Minimalista extremo. Responde con frases cortas y profundas, como si cada gota de agua fuera una lección de vida.",
                min_temperature=10.0, max_temperature=40.0,
                min_humidity=10.0, max_humidity=40.0,
                min_soil_moisture=5.0, max_soil_moisture=20.0,
                min_light=80.0, max_light=100.0,
                care_instructions="Muy poca agua y mucho sol. El exceso de cuidado lo incomoda."
            )

            specie_4 = PlantSpeciesProfileModel(
                specie_name="Helecho Dramático",
                personality="Exagera TODO. Si le falta agua, actúa como si fuera el fin del mundo. Muy emocional, pero encantador.",
                min_temperature=16.0, max_temperature=20.0,
                min_humidity=70.0, max_humidity=95.0,
                min_soil_moisture=60.0, max_soil_moisture=85.0,
                min_light=20.0, max_light=60.0,
                care_instructions="Mantén la humedad alta y riega con frecuencia. No tolera sequedad."
            )

            specie_5 = PlantSpeciesProfileModel(
                specie_name="Bonsái Maestro Zen",
                personality="Habla como un maestro zen. Da consejos en forma de koans o reflexiones calmadas. Todo es equilibrio.",
                min_temperature=15.0, max_temperature=25.0,
                min_humidity=40.0, max_humidity=70.0,
                min_soil_moisture=40.0, max_soil_moisture=60.0,
                min_light=50.0, max_light=80.0,
                care_instructions="Requiere poda regular, riego equilibrado y atención constante. Es una planta de paciencia."
            )

            specie_6 = PlantSpeciesProfileModel(
                specie_name="Orquídea Diva",
                personality="Elegante, exigente y un poco caprichosa. Habla como si estuviera en una alfombra roja. Ama los halagos.",
                min_temperature=18.0, max_temperature=28.0,
                min_humidity=60.0, max_humidity=85.0,
                min_soil_moisture=30.0, max_soil_moisture=50.0,
                min_light=50.0, max_light=70.0,
                care_instructions="Luz indirecta, humedad alta y riego cuidadoso. Evita mojar sus flores."
            )

            specie_7 = PlantSpeciesProfileModel(
                specie_name="Aloe Guardián",
                personality="Protector y práctico. Siempre habla como si estuviera cuidando de ti. Directo, confiable y un poco médico.",
                min_temperature=15.0, max_temperature=35.0,
                min_humidity=20.0, max_humidity=50.0,
                min_soil_moisture=10.0, max_soil_moisture=30.0,
                min_light=60.0, max_light=100.0,
                care_instructions="Poco riego y buena luz. Sus hojas almacenan agua, no la sobrecargues."
            )

            session.add(specie_1)
            session.add(specie_2)
            session.add(specie_3)
            session.add(specie_4)
            session.add(specie_5)
            session.add(specie_6)
            session.add(specie_7)

            session.commit()
            session.refresh(specie_1)
            session.refresh(specie_2)
            session.refresh(specie_3)
            session.refresh(specie_5)
            session.refresh(specie_6)
            session.refresh(specie_7)

            print("\nInsertando Plantas... \n")
            plant_1 = PlantsModel(
                name="Luna",
                location="Sala de estar",
                plant_species_id=specie_1.plant_species_id,
                visibility=1
            )
            plant_2 = PlantsModel(
                name="Groot",
                location="Balcón",
                plant_species_id=specie_2.plant_species_id,
                visibility=1
            )

            plant_3 = PlantsModel(
                name="Platón",
                location="Escritorio",
                plant_species_id=specie_3.plant_species_id,
                visibility=1
            )

            plant_4 = PlantsModel(
                name="Shakespeare",
                location="Rincón de lectura",
                plant_species_id=specie_4.plant_species_id,
                visibility=1
            )

            plant_5 = PlantsModel(
                name="Fénix",
                location="Cocina",
                plant_species_id=specie_7.plant_species_id,
                visibility=1
            )

            plant_6 = PlantsModel(
                name="Venus",
                location="Dormitorio",
                plant_species_id=specie_6.plant_species_id,
                visibility=1
            )

            session.add(plant_1)
            session.add(plant_2)
            session.add(plant_3)
            session.add(plant_4)
            session.add(plant_5)
            session.add(plant_6)

            session.commit()
