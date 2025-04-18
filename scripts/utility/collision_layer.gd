class_name CollisionLayer


const NONE := 0
const WORLD := 1 << 0
const BOMB := 1 << 1
const PIECE := 1 << 2
const DEBRIS := 1 << 3
const EXPLOSION_RAYCAST := WORLD | PIECE
const ALL := 0xFFFFFFFF
