
class GlobalMercator {
  //  TMS Global Mercator Profile
  //  ---------------------------
  //
  //  Functions necessary for generation of tiles in Spherical Mercator projection,
  //  EPSG:900913 (EPSG:gOOglE, Google Maps Global Mercator), EPSG:3785, OSGEO:41001.
  //
  //  Such tiles are compatible with Google Maps, Microsoft Virtual Earth, Yahoo Maps,
  //  UK Ordnance Survey OpenSpace API, ...
  //  and you can overlay them on top of base maps of those web mapping applications.
  //  
  //  Pixel and tile coordinates are in TMS notation (origin [0,0] in bottom-left).
  //
  //  What coordinate conversions do we need for TMS Global Mercator tiles::
  //
  //       LatLon      <->       Meters      <->     Pixels    <->       Tile     
  //
  //   WGS84 coordinates   Spherical Mercator  Pixels in pyramid  Tiles in pyramid
  //       lat/lon            XY in metres     XY pixels Z zoom      XYZ from TMS 
  //      EPSG:4326           EPSG:900913                                         
  //       .----.              ---------               --                TMS      
  //      /      \     <->     |       |     <->     /----/    <->      Google    
  //      \      /             |       |           /--------/          QuadTree   
  //       -----               ---------         /------------/                   
  //     KML, public         WebMapService         Web Clients      TileMapService
  //
  //  What is the coordinate extent of Earth in EPSG:900913?
  //
  //    [-20037508.342789244, -20037508.342789244, 20037508.342789244, 20037508.342789244]
  //    Constant 20037508.342789244 comes from the circumference of the Earth in meters,
  //    which is 40 thousand kilometers, the coordinate origin is in the middle of extent.
  //      In fact you can calculate the constant as: 2 * math.pi * 6378137 / 2.0
  //    $ echo 180 85 | gdaltransform -s_srs EPSG:4326 -t_srs EPSG:900913
  //    Polar areas with abs(latitude) bigger then 85.05112878 are clipped off.
  //
  //  What are zoom level constants (pixels/meter) for pyramid with EPSG:900913?
  //
  //    whole region is on top of pyramid (zoom=0) covered by 256x256 pixels tile,
  //    every lower zoom level resolution is always divided by two
  //    initialResolution = 20037508.342789244 * 2 / 256 = 156543.03392804062
  //
  //  What is the difference between TMS and Google Maps/QuadTree tile name convention?
  //
  //    The tile raster itself is the same (equal extent, projection, pixel size),
  //    there is just different identification of the same raster tile.
  //    Tiles in TMS are counted from [0,0] in the bottom-left corner, id is XYZ.
  //    Google placed the origin [0,0] to the top-left corner, reference is XYZ.
  //    Microsoft is referencing tiles by a QuadTree name, defined on the website:
  //    http://msdn2.microsoft.com/en-us/library/bb259689.aspx
  //
  //  The lat/lon coordinates are using WGS84 datum, yeh?
  //
  //    Yes, all lat/lon we are mentioning should use WGS84 Geodetic Datum.
  //    Well, the web clients like Google Maps are projecting those coordinates by
  //    Spherical Mercator, so in fact lat/lon coordinates on sphere are treated as if
  //    the were on the WGS84 ellipsoid.
  //   
  //    From MSDN documentation:
  //    To simplify the calculations, we use the spherical form of projection, not
  //    the ellipsoidal form. Since the projection is used only for map display,
  //    and not for displaying numeric coordinates, we don't need the extra precision
  //    of an ellipsoidal projection. The spherical projection causes approximately
  //    0.33 percent scale distortion in the Y direction, which is not visually noticable.
  //
  //  How do I create a raster in EPSG:900913 and convert coordinates with PROJ.4?
  //
  //    You can use standard GIS tools like gdalwarp, cs2cs or gdaltransform.
  //    All of the tools supports -t_srs 'epsg:900913'.
  //
  //    For other GIS programs check the exact definition of the projection:
  //    More info at http://spatialreference.org/ref/user/google-projection/
  //    The same projection is degined as EPSG:3785. WKT definition is in the official
  //    EPSG database.
  //
  //    Proj4 Text:
  //      +proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0
  //      +k=1.0 +units=m +nadgrids=@null +no_defs
  //
  //    Human readable WKT format of EPGS:900913:
  //       PROJCS["Google Maps Global Mercator",
  //           GEOGCS["WGS 84",
  //               DATUM["WGS_1984",
  //                   SPHEROID["WGS 84",6378137,298.2572235630016,
  //                       AUTHORITY["EPSG","7030"]],
  //                   AUTHORITY["EPSG","6326"]],
  //               PRIMEM["Greenwich",0],
  //               UNIT["degree",0.0174532925199433],
  //               AUTHORITY["EPSG","4326"]],
  //           PROJECTION["Mercator_1SP"],
  //           PARAMETER["central_meridian",0],
  //           PARAMETER["scale_factor",1],
  //           PARAMETER["false_easting",0],
  //           PARAMETER["false_northing",0],
  //           UNIT["metre",1,
  //               AUTHORITY["EPSG","9001"]]]

  int tileSize=256;
  float initialResolution;
  float originShift;

  GlobalMercator() {
    //Initialize the TMS Global Mercator pyramid"
    this.initialResolution = 2 * PI * 6378137 / this.tileSize;
    //156543.03392804062 for tileSize 256 pixels
    this.originShift = 2 * PI * 6378137 / 2.0;
    //20037508.342789244
  }

  PVector LatLonToMeters(float lat, float lon ) {
    //"Converts given lat/lon in WGS84 Datum to XY in Spherical Mercator EPSG:900913"

    float mx = lon * this.originShift / 180.0;
    float my = log( tan((90 + lat) * PI / 360.0 )) / (PI / 180.0);

    my = my * this.originShift / 180.0;
    return new PVector(mx, my);
  }

  PVector MetersToLatLon(float mx, float my ) {
    //"Converts XY point from Spherical Mercator EPSG:900913 to lat/lon in WGS84 Datum"

    float lon = (mx / this.originShift) * 180.0;
    float lat = (my / this.originShift) * 180.0;

    lat = 180 / PI * (2 * atan( exp( lat * PI / 180.0)) - PI / 2.0);
    return new PVector(lat, lon);
  }

  PVector PixelsToMeters(float px, float py, int zoom) {
    //"Converts pixel coordinates in given zoom level of pyramid to EPSG:900913"

    float res = this.Resolution( zoom );
    float mx = px * res - this.originShift;
    float my = py * res - this.originShift;
    return new PVector(mx, my);
  }

  PVector MetersToPixels(float mx, float my, int zoom) {
    //"Converts EPSG:900913 to pyramid pixel coordinates in given zoom level"

    float res = this.Resolution( zoom );
    float px = (mx + this.originShift) / res;
    float py = (my + this.originShift) / res;
    return new PVector( px, py );
  }

  PVector PixelsToTile( float px, float py) {
    //"Returns a tile covering region in given pixel coordinates"

    int tx = int( ceil( px / float(this.tileSize) ) - 1 );
    int ty = int( ceil( py / float(this.tileSize) ) - 1 );
    return new PVector(tx, ty);
  }

  PVector PixelsToRaster(float px, float py, int zoom) {
    //"Move the origin of pixel coordinates to top-left corner"

    int mapSize = this.tileSize << zoom;
    return new PVector( px, mapSize - py );
  }

  PVector MetersToTile(float mx, float my, int zoom) {
    //"Returns tile for given mercator coordinates"

    PVector pp = this.MetersToPixels( mx, my, zoom);
    return this.PixelsToTile( pp.x, pp.y );
  }

  PVector[] TileBounds(int tx, int ty, int zoom) {
    //"Returns bounds of the given tile in EPSG:900913 coordinates"

    PVector ll = this.PixelsToMeters( tx*this.tileSize, ty*this.tileSize, zoom );
    PVector ur = this.PixelsToMeters( (tx+1)*this.tileSize, (ty+1)*this.tileSize, zoom );

    PVector[] ret = new PVector[2];
    ret[0]=ll;
    ret[1]=ur;
    return ret;
  }

  //  def TileLatLonBounds(self, tx, ty, zoom ):
  //    "Returns bounds of the given tile in latutude/longitude using WGS84 datum"
  //
  //    bounds = self.TileBounds( tx, ty, zoom)
  //    minLat, minLon = self.MetersToLatLon(bounds[0], bounds[1])
  //    maxLat, maxLon = self.MetersToLatLon(bounds[2], bounds[3])
  //     
  //    return ( minLat, minLon, maxLat, maxLon )

  float Resolution( int zoom ) {
    //"Resolution (meters/pixel) for given zoom level (measured at Equator)"

    //# return (2 * math.pi * 6378137) / (self.tileSize * 2**zoom)
    return this.initialResolution / (pow(2, zoom));
  }

  //  def ZoomForPixelSize(self, pixelSize ):
  //    "Maximal scaledown zoom of the pyramid closest to the pixelSize."
  //    
  //    for i in range(30):
  //      if pixelSize > self.Resolution(i):
  //        return i-1 if i!=0 else 0 # We don't want to scale up
  //
  PVector GoogleTile(int tx, int ty, int zoom) {
    //"Converts TMS tile coordinates to Google Tile coordinates"

    // coordinate origin is moved from bottom-left to top-left corner of the extent
    return new PVector(tx, (pow(2, zoom) - 1) - ty);
  }
 
  //
  //  def QuadTree(self, tx, ty, zoom ):
  //    "Converts TMS tile coordinates to Microsoft QuadTree"
  //    
  //    quadKey = ""
  //    ty = (2**zoom - 1) - ty
  //    for i in range(zoom, 0, -1):
  //      digit = 0
  //      mask = 1 << (i-1)
  //      if (tx & mask) != 0:
  //        digit += 1
  //      if (ty & mask) != 0:
  //        digit += 2
  //      quadKey += str(digit)
  //      
  //    return quadKey
  
        PVector QuadKeyToTileXY(String quadKey)
        {
            int tileX;
            int tileY;
            int levelOfDetail;
          
            tileX = tileY = 0;
            levelOfDetail = quadKey.length();
            for (int i = levelOfDetail; i > 0; i--)
            {
                int mask = 1 << (i - 1);
                switch (quadKey.charAt(levelOfDetail - i))
                {
                    case '0':
                        break;

                    case '1':
                        tileX |= mask;
                        break;

                    case '2':
                        tileY |= mask;
                        break;

                    case '3':
                        tileX |= mask;
                        tileY |= mask;
                        break;

                }
            }
            
            return new PVector(tileX,tileY,levelOfDetail);
        }
}
