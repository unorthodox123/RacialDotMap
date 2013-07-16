import sys
from osgeo import ogr
from shapely.wkb import loads
from shapely.geometry import *
from random import uniform
import sqlite3

# Import the module that converts spatial data between formats

sys.path.append("filepath")
from globalmaptiles import GlobalMercator

# Main function that reads the shapefile, obtains the population counts,
# creates a point object for each person by race, and exports to a SQL database.

def main(input_filename, output_filename):
    
    # Create a GlobalMercator object for later conversions
    
    merc = GlobalMercator()

    # Open the shapefile
    
    ds = ogr.Open(input_filename)
    
    if ds is None:
        print "Open failed.\n"
        sys.exit( 1 )

    # Obtain the first (and only) layer in the shapefile
    
    lyr = ds.GetLayerByIndex(0)

    lyr.ResetReading()

    # Obtain the field definitions in the shapefile layer

    feat_defn = lyr.GetLayerDefn()
    field_defns = [feat_defn.GetFieldDefn(i) for i in range(feat_defn.GetFieldCount())]

    # Obtain the index of the field for the count for whites, blacks, Asians, 
    # Others, and Hispanics.
    
    for i, defn in enumerate(field_defns):
        
        if defn.GetName() == "POP10":
            pop_field = i
            
        if defn.GetName() == "nh_white_n":
            white_field = i
            
        if defn.GetName() == "nh_black_n":
            black_field = i
            
        if defn.GetName() == "nh_asian_n":
            asian_field = i
            
        if defn.GetName() == "hispanic_n":
            hispanic_field = i
            
        if defn.GetName() == "NH_Other_n":
            other_field = i
            
        if defn.GetName() == "STATEFP10":
            statefips_field = i

    # Set-up the output file
    
    conn = sqlite3.connect( output_filename )
    c = conn.cursor()
    c.execute( "create table if not exists people_by_race (statefips text, x text, y text, quadkey text, race_type text)" )

    # Obtain the number of features (Census Blocks) in the layer
    
    n_features = len(lyr)

    # Iterate through every feature (Census Block Ploygon) in the layer,
    # obtain the population counts, and create a point for each person within
    # that feature.

    for j, feat in enumerate( lyr ):
        
        # Print a progress read-out for every 1000 features and export to hard disk
        
        if j % 1000 == 0:
            conn.commit()
            print "%s/%s (%0.2f%%)"%(j+1,n_features,100*((j+1)/float(n_features)))
            
        # Obtain total population, racial counts, and state fips code of the individual census block

        pop = int(feat.GetField(pop_field))
        white = int(feat.GetField(white_field))
        black = int(feat.GetField(black_field))
        asian = int(feat.GetField(asian_field))
        hispanic = int(feat.GetField(hispanic_field))
        other = int(feat.GetField(other_field))
        statefips = feat.GetField(statefips_field)

        # Obtain the OGR polygon object from the feature

        geom = feat.GetGeometryRef()
        
        if geom is None:
            continue
        
        # Convert the OGR Polygon into a Shapely Polygon
        
        poly = loads(geom.ExportToWkb())
        
        if poly is None:
            continue        
            
        # Obtain the "boundary box" of extreme points of the polygon

        bbox = poly.bounds
        
        if not bbox:
            continue
     
        leftmost,bottommost,rightmost,topmost = bbox
    
        # Generate a point object within the census block for every person by race
       
        for i in range(white):
                
            # Choose a random longitude and latitude within the boundary box
            # and within the orginial ploygon of the census block
                
            while True:
                    
                samplepoint = Point(uniform(leftmost, rightmost),uniform(bottommost, topmost))
                    
                if samplepoint is None:
                    break
                
                if poly.contains(samplepoint):
                    break
    
            # Convert the longitude and latitude coordinates to meters and
            # a tile reference
    
            x, y = merc.LatLonToMeters(samplepoint.y,samplepoint.x)
            tx,ty = merc.MetersToTile(x, y, 21)
                
            # Create a unique quadkey for each point object
                
            quadkey = merc.QuadTree(tx, ty, 21)
                
            # Create categorical variable for the race category
                   
            race_type = 'w'         
    
            # Export data to the database file
    
            c.execute( "insert into people_by_race values (?,?,?,?,?)", (statefips, x, y, quadkey,race_type) )

        for i in range(black):
                
            # Choose a random longitude and latitude within the boundary box
            # points and within the orginial ploygon of the census block
                
            while True:
                    
                samplepoint = Point(uniform(leftmost, rightmost),uniform(bottommost, topmost))
                    
                if samplepoint is None:
                    break
                    
                if poly.contains(samplepoint):
                    break
    
            # Convert the longitude and latitude coordinates to meters and
            # a tile reference
    
            x, y = merc.LatLonToMeters(samplepoint.y,samplepoint.x)
            tx,ty = merc.MetersToTile(x, y, 21)
                            
            # Create a unique quadkey for each point object
                
            quadkey = merc.QuadTree(tx, ty, 21)
                
            # Create categorical variable for the race category
                   
            race_type = 'b'         
    
            # Export data to the database file
    
            c.execute( "insert into people_by_race values (?,?,?,?,?)", (statefips, x, y, quadkey,race_type) )

        for i in range(asian):
                
            # Choose a random longitude and latitude within the boundary box
            # points and within the orginial ploygon of the census block
                
            while True:
                    
                samplepoint = Point(uniform(leftmost, rightmost),uniform(bottommost, topmost))
                    
                if samplepoint is None:
                    break
                    
                if poly.contains(samplepoint):
                    break
    
            # Convert the longitude and latitude coordinates to meters and
            # a tile reference
    
            x, y = merc.LatLonToMeters(samplepoint.y,samplepoint.x)
            tx,ty = merc.MetersToTile(x, y, 21)
                            
            # Create a unique quadkey for each point object
                
            quadkey = merc.QuadTree(tx, ty, 21)
                
            # Create categorical variable for the race category
                   
            race_type = 'a'         
    
            # Export data to the database file
    
            c.execute( "insert into people_by_race values (?,?,?,?,?)", (statefips, x, y, quadkey,race_type) )

        for i in range(hispanic):
                
            # Choose a random longitude and latitude within the boundary box
            # points and within the orginial ploygon of the census block
                
            while True:
                    
                samplepoint = Point(uniform(leftmost, rightmost),uniform(bottommost, topmost))
                    
                if samplepoint is None:
                    break
                    
                if poly.contains(samplepoint):
                    break
    
            # Convert the longitude and latitude coordinates to meters and
            # a tile reference
    
            x, y = merc.LatLonToMeters(samplepoint.y,samplepoint.x)
            tx,ty = merc.MetersToTile(x, y, 21)
                            
            # Create a unique quadkey for each point object
                
            quadkey = merc.QuadTree(tx, ty, 21)
                
            # Create categorical variable for the race category
                   
            race_type = 'h'         
    
            # Export data to the database file
    
            c.execute( "insert into people_by_race values (?,?,?,?,?)", (statefips, x, y, quadkey,race_type) )

        for i in range(other):
                
            # Choose a random longitude and latitude within the boundary box
            # points and within the orginial ploygon of the census block
                
            while True:
                    
                samplepoint = Point(uniform(leftmost, rightmost),uniform(bottommost, topmost))
                    
                if samplepoint is None:
                    break
                    
                if poly.contains(samplepoint):
                    break
    
            # Convert the longitude and latitude coordinates to meters and
            # a tile reference
    
            x, y = merc.LatLonToMeters(samplepoint.y,samplepoint.x)
            tx,ty = merc.MetersToTile(x, y, 21)
                            
            # Create a unique quadkey for each point object
                
            quadkey = merc.QuadTree(tx, ty, 21)
                
            # Create categorical variable for the race category
                   
            race_type = 'o'         
    
            # Export data to the database file
    
            c.execute( "insert into people_by_race values (?,?,?,?,?)", (statefips, x, y, quadkey,race_type) )
    
    conn.commit()

# Execution code...

if __name__=='__main__':
    
    for state in ['01','02','04','05','06','08','09','10','11','12','13','15',
        '16','17','18','19','20','21','22','23','24','25','26','27','28','29','30',
        '31','32','33','34','35','36','37','38','39','40','41','42','44','45','46',
        '47','48','49','50','51','53','54','55','56']:
        
        print "state:%s"%state
        
        main( ".../Census Data/statefile_"+state+".shp", 
        ".../Map Data/people_by_race5.db")
