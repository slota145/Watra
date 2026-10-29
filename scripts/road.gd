class_name Road
## Pomocnicze funkcje do wyznaczania krętej drogi: losowo wygięte punkty kontrolne
## wygładzone krzywą Catmulla-Roma i gęsto próbkowane (współrzędne w kafelkach).


## Kręta droga z `from` do `to`: punkty co ~`segment` kafelków odsunięte w bok
## maksymalnie o `amplitude`, wygładzone i próbkowane co `step`.
static func wiggle(from: Vector2, to: Vector2, rng: RandomNumberGenerator, amplitude := 5.0, segment := 11.0, step := 0.5) -> PackedVector2Array:
	var controls: Array[Vector2] = [from]
	var count := maxi(2, int(from.distance_to(to) / segment))
	var normal := (to - from).normalized().orthogonal()
	for i in range(1, count):
		controls.append(from.lerp(to, float(i) / count) + normal * rng.randf_range(-amplitude, amplitude))
	controls.append(to)
	return smooth(controls, step)


## Odcinek prosty próbkowany co `step`.
static func straight(from: Vector2, to: Vector2, step := 0.5) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := maxi(1, ceili(from.distance_to(to) / step))
	for i in count + 1:
		points.append(from.lerp(to, float(i) / count))
	return points


## Krzywa Catmulla-Roma przechodząca przez wszystkie punkty kontrolne.
static func smooth(controls: Array[Vector2], step := 0.5) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in controls.size() - 1:
		var p0 := controls[maxi(i - 1, 0)]
		var p1 := controls[i]
		var p2 := controls[i + 1]
		var p3 := controls[mini(i + 2, controls.size() - 1)]
		var samples := maxi(1, ceili(p1.distance_to(p2) / step))
		for s in samples:
			var t := float(s) / samples
			var t2 := t * t
			var t3 := t2 * t
			points.append(0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3))
	points.append(controls.back())
	return points


## Najmniejsza odległość punktu od drogi.
static func distance_to(point: Vector2, path: PackedVector2Array) -> float:
	var best := INF
	for p in path:
		best = minf(best, point.distance_squared_to(p))
	return sqrt(best)
