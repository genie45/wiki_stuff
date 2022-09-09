/* Any JavaScript here will be loaded for all users on every page load. */

/* Local script text override table

   Uncomment below and edit to provide translations strings before copying over into scripts on English
   wiki.
   For example, to override Spawn Maps' strings "Creature Spawns" and "Select a creature":
   window.arkLocalI18n = {
       SpawnMaps: {
           CreatureSpawns: 'Troodon Spawns',
           SelectCreature: 'Select a Troodon friend',
       }
   }
*/
// window.arkLocalI18n = {};

/* ↓ GLOBAL JS FROM ENGLISH WIKI ↓ */
mw.loader.state( { 'en:site': 'loading' } );
mw.loader.load( '/load.php?lang=en&modules=site&only=scripts&skin=vector' );
/* ↓ INTERNAL TRANSLATION WIKI JS ↓ */
