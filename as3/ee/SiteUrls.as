/*
*   SiteUrls
*   for ActionScript 3.0
*   loads corresponding file and asset domains 
*   based on original SiteUrls class AS2 version by Ryan Quigley
*
*   @author     Arbie Almeida
*   @version    1.0.0
*
*   --VERSION HISTORY--
*   11.14.08 (1.0.0) - first version
*/
/*
##### USAGE #####

::dev environment initialization::
    SiteUrls.defineDevUrls(site_name:String, dev_url:String);       -sets SiteUrls.site to passed dev URL, gets corresponding site file locations

::retrieves set URLS::
    var site_url:String = SiteUrls.site;                -retrieval functions, actual addresses defined externally
    var assets_url:String = SiteUrls.assets;
    var files_url:String = SiteUrls.files;
    
::manual forced setup of URLS::
    SiteUrls.forceSetup();              -forces SiteUrls to setup URLS before any retrieval functions are called.
*/

package ee
{
    import flash.external.*;
    import flash.system.*;
    
    public class SiteUrls
    {
        private static var _using_dev_urls:Boolean = false;
        private static var _init:Boolean = false;
        
        private static var _site:String = "undefined";
        private static var _assets:String = "undefined";
        private static var _files:String = "undefined";
        
        private static function _setup():void
        {
            var urls = ExternalInterface.call("SiteUrls.getUrls");
            if(!urls) {
                return;
            }
            
            SiteUrls._site = urls.site;
            SiteUrls._assets = urls.assets;
            SiteUrls._files = urls.files;
            
            SiteUrls._securityAllow();
        }
        
        private static function _securityAllow():void
        {
            Security.allowDomain(SiteUrls.extractUrl(SiteUrls._site));
            Security.allowDomain(SiteUrls.extractUrl(SiteUrls._assets));
            Security.allowDomain(SiteUrls.extractUrl(SiteUrls._files));
            SiteUrls._init = true;
        }
        
        public static function forceSetup():void
        {
            if(SiteUrls._init === false) {
                SiteUrls._setup();
            }
        }
        
        public static function defineDevUrls(site:String, site_url:String):String
        {
            if((site) && (site != "") && (site_url) && (site_url != "")) {
                SiteUrls._using_dev_urls = true;

                SiteUrls._site = site_url;
                SiteUrls._assets = 'http://asset_server.dev/' + site + '/site/';
        		SiteUrls._files = 'http://image_server.dev/' + site + '/';

                SiteUrls._securityAllow();

                trace("\n\n---!! DISABLE TRACING BEFORE SYNC !!---\n");
                return "";
            } else {
                trace("SiteUrls.defineDevUrls() - ERROR: passed site name/site url missing");
                return "";
            }   
        }
        
        public static function get site():String
        {
            if(SiteUrls._init === false) {
                SiteUrls._setup();
            }
            return _site;
        }
        
        public static function get assets():String
        {
            if(SiteUrls._init === false) {
                SiteUrls._setup();
            }
            return _assets;
        }
        
        public static function get files():String
        {
            if(SiteUrls._init === false) {
                SiteUrls._setup();
            }
            return _files;
        }
        
        private static function extractUrl(url:String, keep_URI:Boolean = false):String
        {
            if(url == "/") {
                return "/";
            }
            
            if(keep_URI === true) {
                var url_start:Number = url.indexOf("://");
                url = url.substr(0, url.indexOf("/", url_start + 3));
            } else {
                if(url.indexOf("http://")) {
                    url = url.substr(6);
                } else if (url.indexOf("https://")) {
                    url = url.substr(7);
                }
                url = url.substr(0, url.indexOf("/"));
            }
            
            return url;
        }
    }
}