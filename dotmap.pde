
BufferedReader reader;
double ll, bb, rr, tt;

float A = 1000.0;

GlobalMercator proj = new GlobalMercator();

class PersonPoint {
  double x, y;
  String quadnode;

  PersonPoint(String row) {
    String[] fields = split(row, ",");
    this.x = Double.parseDouble(fields[1])/A;
    this.y = Double.parseDouble(fields[2])/A;
    this.quadnode = fields[3];
  }

  void draw(PGraphics pg) {
    pg.point((float)this.x, (float)this.y);
  }
}

ArrayList people;

float pointWeight(int level) {
  switch(level) {
  case 4: 
      return 0.01;
  case 5: 
      return 0.01;
  case 6: 
      return 0.01;
  case 7: 
      return 0.01;
  case 8: 
      return 0.01;
  case 9: 
      return 0.02;
  case 10: 
      return 0.02;
  case 11: 
      return 0.02;
  case 12: 
      return 0.02;
  case 13: 
      return 0.02;
  default: 
    return 0.0;
  }
}

float transparent(int level) {
  switch(level) {
  case 4: 
      return 153;
  case 5: 
      return 153;
  case 6: 
      return 179;
  case 7: 
      return 179;
  case 8: 
      return 204;
  case 9: 
      return 204;
  case 10: 
      return 230;
  case 11: 
      return 230;
  case 12: 
      return 255;
  case 13: 
      return 255;
  default: 
    return 0.0;
  }
}

void setup(){
  
  size(512, 512, JAVA2D);
  smooth(8);

  String[] zoomlevels = loadStrings(".../zoomlevel.txt");  // a text file with lines 4, 5, 6 ...etc. specifing zoomlevel

  for ( int i=0; i<zoomlevels.length; i++ ) {

    int level = int(zoomlevels[i]);

    println( "loading..." );
    reader = createReader(".../peoplesort_by_race.csv");  // the datafile (converted to .csv) sorted by quadkey
    try {
      String line;

      String quadkey = "";
      PGraphics pg = null;
      PVector tms_tile = null;
      
      int rown = 0;
      
      line = reader.readLine();
      
      while (true) {
        
        line = reader.readLine();
        
        if (line==null || line.length()==0) {
          println( "file done" );
          break;
        }
        
        rown += 1;
        
        if (rown % 100000 == 0) {
          println( rown );
        }

        String[] fields = split(line, ",");
        float px = float(fields[1])/A;
        float py = float(fields[2])/A;
        String newQuadkey = fields[3].substring(0,level);
        String race_type = fields[4].substring(0, 1);

        if ( !newQuadkey.equals( quadkey ) ) {
          
          //finish up the last tile
          if (pg!=null) {
            pg.endDraw();
            PVector gtile = proj.GoogleTile((int)tms_tile.x, (int)tms_tile.y, level);
            println( "C:/Users/Local Admin/Desktop/Weldon Cooper Center/Dot Mapping/tiles4/"+level+"/"+int(gtile.x)+"/"+int(gtile.y)+".png" );
            pg.save( "C:/Users/Local Admin/Desktop/Weldon Cooper Center/Dot Mapping/tiles4/"+level+"/"+int(gtile.x)+"/"+int(gtile.y)+".png" );
            println( "done" );
          }

          quadkey = newQuadkey;
          
          PVector google_tile = proj.QuadKeyToTileXY( newQuadkey );
          tms_tile = proj.GoogleTile( (int)google_tile.x, (int)google_tile.y, level );

          println( level+" "+tms_tile.x+" "+tms_tile.y );

          pg = createGraphics(512, 512, JAVA2D);
          pg.beginDraw();
          pg.smooth(8);

          PVector[] bounds = proj.TileBounds( (int)tms_tile.x, (int)tms_tile.y, level );

          float tile_ll = bounds[0].x/A;
          float tile_bb = bounds[0].y/A;
          float tile_rr = bounds[1].x/A;
          float tile_tt = bounds[1].y/A;

          double xscale = width/(tile_rr-tile_ll);
          double yscale = width/(tile_tt-tile_bb);
          float scale = min((float)xscale, (float)yscale);

          pg.scale(scale,-scale);
          
          pg.translate(-(float)tile_ll, -(float)tile_tt);

          pg.strokeWeight(pointWeight(level));
          
          pg.background(255);
        
        }
        
        if (race_type.equals("w")) {
          pg.stroke(#73B2FF, transparent(level));
          pg.point(px, py);
        }
          
        if (race_type.equals("b")) {
          pg.stroke(159,212,0, transparent(level));
          pg.point(px, py);
        }
        
        if (race_type.equals("a")) {
          pg.stroke(255,0,0, transparent(level));
          pg.point(px, py);
        }
          
        if (race_type.equals("h")) {
          pg.stroke(255,170,0, transparent(level));
          pg.point(px, py);
        }
          
        if (race_type.equals("o")) {
          pg.stroke(#996633, transparent(level));
          pg.point(px, py);
        }
       
      }

      if (pg!=null) {
        pg.endDraw();
        PVector gtile = proj.GoogleTile((int)tms_tile.x, (int)tms_tile.y, level);
        pg.save( "C:/Users/Local Admin/Desktop/Weldon Cooper Center/Dot Mapping/tiles4/"+level+"/"+int(gtile.x)+"/"+int(gtile.y)+".png" );
        println( "done" );
      }
    } 
    catch (IOException e) {
      //e.printStackTrace();
    }
  }
}

void draw() {
}
