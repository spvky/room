/* How should clouds work
1. top empty tile of any rain effected row/column has a cloud entity
2. Cloud entity raycasts down until it hits a solid surface
3. On hitting a solid surface creat a water source
4. Water

may be better to look at solid tiles and identify

Single Cloud entity parent on top empty row
based on (width / tilesize) it casts that many rays down to detect where the water should be,
it also tracks total water

Cloud_Data :: struct {
	
}

*/
