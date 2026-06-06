/******************************************************************
            ANALYSE GÉOSPATIALE AVEC SQL SERVER
      Compatible SQL Server Spatial (GEOMETRY / GEOGRAPHY)
******************************************************************/

/*===============================================================
1. CRÉATION D'UNE TABLE GÉOSPATIALE
===============================================================*/

CREATE TABLE Sites
(
    IdSite INT IDENTITY(1,1) PRIMARY KEY,
    NomSite NVARCHAR(200),
    Province NVARCHAR(100),
    Ville NVARCHAR(100),
    Latitude FLOAT,
    Longitude FLOAT,
    Position GEOGRAPHY
);


/*===============================================================
2. INSERTION DES DONNÉES GPS
===============================================================*/

INSERT INTO Sites
(
    NomSite,
    Province,
    Ville,
    Latitude,
    Longitude,
    Position
)
VALUES
(
    'Hôpital Général de Goma',
    'Nord-Kivu',
    'Goma',
    -1.6788,
    29.2218,
    GEOGRAPHY::Point(-1.6788,29.2218,4326)
);


/*===============================================================
3. AFFICHER LES COORDONNÉES
===============================================================*/

SELECT
    IdSite,
    NomSite,
    Latitude,
    Longitude
FROM Sites;


/*===============================================================
4. DISTANCE ENTRE DEUX POINTS
===============================================================*/

DECLARE @PointA GEOGRAPHY;
DECLARE @PointB GEOGRAPHY;

SET @PointA =
GEOGRAPHY::Point(-1.6788,29.2218,4326);

SET @PointB =
GEOGRAPHY::Point(-1.7020,29.2400,4326);

SELECT
    @PointA.STDistance(@PointB)
    AS DistanceMetres;


/*===============================================================
5. RECHERCHE DES SITES DANS UN RAYON DE 5 KM
===============================================================*/

DECLARE @Centre GEOGRAPHY;

SET @Centre =
GEOGRAPHY::Point(-1.6788,29.2218,4326);

SELECT
    IdSite,
    NomSite,
    Position.STDistance(@Centre)
    AS DistanceMetres
FROM Sites
WHERE Position.STDistance(@Centre)
      <= 5000
ORDER BY DistanceMetres;


/*===============================================================
6. CALCUL DE LA DISTANCE ENTRE TOUTES LES VILLES
===============================================================*/

SELECT
    A.NomSite AS SiteA,
    B.NomSite AS SiteB,
    A.Position.STDistance(B.Position)
    AS DistanceMetres
FROM Sites A
INNER JOIN Sites B
ON A.IdSite < B.IdSite;


/*===============================================================
7. NOMBRE DE SITES PAR PROVINCE
===============================================================*/

SELECT
    Province,
    COUNT(*) AS NombreSites
FROM Sites
GROUP BY Province
ORDER BY NombreSites DESC;


/*===============================================================
8. DENSITÉ PAR ZONE
===============================================================*/

SELECT
    Province,
    Ville,
    COUNT(*) AS NombrePoints
FROM Sites
GROUP BY Province, Ville
ORDER BY NombrePoints DESC;


/*===============================================================
9. CENTROÏDE GÉOGRAPHIQUE
===============================================================*/

SELECT
    AVG(Latitude) AS LatitudeCentre,
    AVG(Longitude) AS LongitudeCentre
FROM Sites;


/*===============================================================
10. DÉTECTION DES SITES ISOLÉS
===============================================================*/

DECLARE @Rayon INT = 10000;

SELECT
    A.IdSite,
    A.NomSite
FROM Sites A
WHERE NOT EXISTS
(
    SELECT 1
    FROM Sites B
    WHERE A.IdSite <> B.IdSite
    AND A.Position.STDistance(B.Position)
        < @Rayon
);


/*===============================================================
11. CLASSEMENT DES SITES LES PLUS PROCHES
===============================================================*/

DECLARE @Reference GEOGRAPHY;

SET @Reference =
GEOGRAPHY::Point(-1.6788,29.2218,4326);

SELECT
    NomSite,
    ROUND(
        Position.STDistance(@Reference),
        0
    ) AS DistanceMetres
FROM Sites
ORDER BY DistanceMetres;


/*===============================================================
12. ANALYSE ÉPIDÉMIOLOGIQUE PAR LOCALISATION
===============================================================*/

SELECT
    Province,
    COUNT(*) AS NombreCas
FROM CasEpidemiologiques
GROUP BY Province
ORDER BY NombreCas DESC;


/*===============================================================
13. TAUX D'INCIDENCE PAR PROVINCE
===============================================================*/

SELECT
    Province,
    Population,
    NombreCas,
    ROUND(
        (
            NombreCas * 100000.0
        )
        /
        Population,
        2
    ) AS TauxIncidence
FROM StatistiquesEpidemiologiques;


/*===============================================================
14. HOTSPOTS ÉPIDÉMIOLOGIQUES
===============================================================*/

SELECT
    Province,
    Ville,
    COUNT(*) AS Cas
FROM CasEpidemiologiques
GROUP BY Province, Ville
HAVING COUNT(*) > 100
ORDER BY Cas DESC;


/*===============================================================
15. CLUSTERING SPATIAL SIMPLE
===============================================================*/

DECLARE @RayonCluster FLOAT = 3000;

SELECT
    A.IdSite,
    A.NomSite,
    COUNT(B.IdSite)
    AS NombreVoisins
FROM Sites A
LEFT JOIN Sites B
ON A.Position.STDistance(B.Position)
    <= @RayonCluster
GROUP BY
    A.IdSite,
    A.NomSite
ORDER BY NombreVoisins DESC;


/*===============================================================
16. ANALYSE DES INTERVENTIONS D'URGENCE
===============================================================*/

SELECT
    IdIntervention,
    Lieu,
    TempsArriveeMinutes,
    Latitude,
    Longitude
FROM InterventionsUrgence
ORDER BY TempsArriveeMinutes;


/*===============================================================
17. TEMPS MOYEN D'INTERVENTION PAR ZONE
===============================================================*/

SELECT
    Province,
    AVG(TempsArriveeMinutes)
        AS TempsMoyen
FROM InterventionsUrgence
GROUP BY Province;


/*===============================================================
18. CARTOGRAPHIE DES INCIDENTS
===============================================================*/

SELECT
    IdIncident,
    TypeIncident,
    DateIncident,
    Latitude,
    Longitude
FROM Incidents;


/*===============================================================
19. ANALYSE DE PROXIMITÉ
===============================================================*/

DECLARE @Hopital GEOGRAPHY;

SET @Hopital =
GEOGRAPHY::Point(-1.6788,29.2218,4326);

SELECT
    NomSite,
    ROUND(
        Position.STDistance(@Hopital),
        0
    ) AS DistanceHopital
FROM Sites
ORDER BY DistanceHopital;


/*===============================================================
20. CORRIDORS DE DÉPLACEMENT
===============================================================*/

SELECT
    IdTrajet,
    PointDepart,
    PointArrivee,
    DistanceKm,
    DureeMinutes
FROM Trajets;


/*===============================================================
21. ANALYSE DES FRONTIÈRES
===============================================================*/

SELECT
    Province,
    COUNT(*) AS SitesFrontaliers
FROM Sites
WHERE DistanceFrontiereKm < 10
GROUP BY Province;


/*===============================================================
22. CRÉATION D'UN INDEX SPATIAL
===============================================================*/

CREATE SPATIAL INDEX IDX_Sites_Position
ON Sites(Position);


/*===============================================================
23. VUE GÉOSPATIALE
===============================================================*/

CREATE OR ALTER VIEW vw_CartographieSites
AS
SELECT
    IdSite,
    NomSite,
    Province,
    Ville,
    Latitude,
    Longitude
FROM Sites;


/*===============================================================
24. TABLEAU DE BORD SIG
===============================================================*/

SELECT
    Province,
    COUNT(*) AS NombreSites,
    AVG(Latitude) AS LatitudeCentre,
    AVG(Longitude) AS LongitudeCentre
FROM Sites
GROUP BY Province;


/*===============================================================
25. RAPPORT GÉOSPATIAL COMPLET
===============================================================*/

SELECT
    COUNT(*) AS NombreTotalSites,
    COUNT(DISTINCT Province)
        AS NombreProvinces,
    COUNT(DISTINCT Ville)
        AS NombreVilles
FROM Sites;


/******************************************************************
      ANALYSES GÉOSPATIALES AVANCÉES POSSIBLES
******************************************************************

✓ Cartographie SIG
✓ Santé publique / Épidémiologie
✓ Analyse humanitaire
✓ Gestion des catastrophes
✓ Surveillance sécuritaire
✓ Analyse criminelle
✓ Gestion des infrastructures
✓ Analyse des déplacements
✓ Optimisation logistique
✓ Réseaux routiers
✓ Géofencing
✓ Détection de clusters spatiaux
✓ Heatmaps
✓ Analyse de proximité
✓ Frontières et corridors
✓ Intégration Power BI Maps
✓ Intégration ArcGIS
✓ Intégration QGIS
✓ Intégration Azure Maps

******************************************************************/