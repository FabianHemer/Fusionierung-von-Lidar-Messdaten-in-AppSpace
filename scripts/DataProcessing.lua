local DataProcessing = {}

local utils = require("utils")

--@removePointsBeyond(inputCloud: PointCloud, maxDistance: double):PointCloud
function DataProcessing.removePointsBeyond(inputCloud, maxDistance)
  local resultCloud = PointCloud.create()
  local size, _, _ = inputCloud:getSize()
  for i = 1, (size - 1) do
    local point, intensity = inputCloud:getPoint3D(i)
    local distance, _ = Point.getDistance(point, Point.create(0, 0, 0))
    if ( distance < maxDistance) then
      resultCloud:appendPoint(point:getX(), point:getY(), point:getZ(), intensity)
    end
  end
  return resultCloud
end

--@getCornersAndEdgeLengths(inputCloud:PointCloud):Point, Int, Point, Int, Float, Point, Int, Float
function DataProcessing.getCornersAndEdgeLengths(inputCloud)
  local closestPoint, firstPoint, lastPoint, pointCloudSize, closestPointIndex, distance, _
  local firstPointIndex, lastPointIndex

  closestPoint, closestPointIndex, _, _ = DataProcessing.getCorners(inputCloud)
  firstPoint, lastPoint, firstPointIndex, lastPointIndex = inputCloud:findMaxDistancePointPair()
  distance = Point.getDistance(firstPoint, lastPoint)
  pointCloudSize = inputCloud:getSize()

  if ((closestPointIndex == 0) or (closestPointIndex == pointCloudSize - 1)) then
    return firstPoint, firstPointIndex, lastPoint, lastPointIndex, distance
  else
    if (distance * 1.1 < (Point.getDistance(firstPoint, closestPoint) + Point.getDistance(lastPoint, closestPoint))) then
      return firstPoint, firstPointIndex, closestPoint, closestPointIndex, Point.getDistance(firstPoint, closestPoint),
        lastPoint, lastPointIndex, Point.getDistance(lastPoint, closestPoint)
    else
      return firstPoint, firstPointIndex, lastPoint, lastPointIndex, distance
    end
  end
end

--@getCorners(inputCloud:PointCloud):Point, Integer, Point, Point
function DataProcessing.getCorners(inputCloud)
  local closestPoint, secondPoint, thirdPoint, closestPointIndex, _
  closestPoint, closestPointIndex = inputCloud:findClosestPoint(utils.originPoint)
  secondPoint, _ = inputCloud:getPoint3D(0)
  thirdPoint, _ = inputCloud:getPoint3D(inputCloud:getSize()-1)
  return closestPoint, closestPointIndex, secondPoint, thirdPoint
end

--rotateAroundPoint(originPoint:Point, pointRotate: Point, angle:number) : point
function DataProcessing.rotateAroundPoint(originPoint, pointRotate, angle)
  local anglerad = math.rad(angle)
  local shiftedPoint = Point.create(pointRotate:getX() - originPoint:getX(), pointRotate:getY() - originPoint:getY())
  local retPoint = Point.create(0,0)

  retPoint:setX(math.cos(anglerad) * shiftedPoint:getX() + (math.sin(anglerad) * shiftedPoint:getY()))
  retPoint:setY(math.sin(anglerad) * shiftedPoint:getX() + (math.cos(anglerad) * shiftedPoint:getY()))
  retPoint:setX(retPoint:getX() + originPoint:getX())
  retPoint:setY(retPoint:getY() + originPoint:getY())

  return retPoint
end


--@getDegree(point1:Point, point2:Point):number
function DataProcessing.getDegree(point1, point2)
  local lenghtp1 = math.sqrt(math.pow(point1:getX(), 2)+math.pow(point1:getY(), 2))
  local lenghtp2 = math.sqrt(math.pow(point2:getX(), 2)+math.pow(point2:getY(), 2))
  local nenner = lenghtp1 * lenghtp2
  local zaehler = (point1:getX()*point2:getX()) + (point1:getY()*point2:getY())
  local degree = math.deg(math.acos(zaehler/nenner))
  return degree
end


--@DataProcessing.checkEdgeLength(length: double, index: int):Boolean
function DataProcessing.checkEdgeLength(length, index)
  local predefinedEdgeLength = utils.predefinedSideLengths[index]
  return predefinedEdgeLength * 0.90 < length and length < predefinedEdgeLength * 1.1
end


--@getThirdCorner(p1:Point, p2: Point): point
function DataProcessing.getThirdCorner(p1, p2)
  -- Get Left Point
  local firstPoint = p2
  local secondPoint = p1
  if (p1:getY() > p2:getY()) then
    firstPoint = p1
    secondPoint = p2
  end
  
  local A = secondPoint:getX() - (firstPoint:getX())
  local G = secondPoint:getY() - (firstPoint:getY())
  local alpha
  if (G ~= 0) then
    alpha = math.deg(math.atan(G/A))
    
  else
    alpha = 0
  end

  if(alpha > 0) then
      alpha = alpha - 180
  end
  
  local edgeLength = math.sqrt(math.pow(A, 2) + math.pow(G, 2))

  if DataProcessing.checkEdgeLength(edgeLength, 1) then
    local deg = (alpha+utils.predefinedAngle[1])
    local retPoint = Point.create(firstPoint:getX() + utils.predefinedSideLengths[2], firstPoint:getY())
    retPoint = DataProcessing.rotateAroundPoint(firstPoint, retPoint, deg)
    return retPoint
  elseif DataProcessing.checkEdgeLength(edgeLength, 2) then
    local deg = (alpha+utils.predefinedAngle[2])
    local retPoint = Point.create(firstPoint:getX() + utils.predefinedSideLengths[3], firstPoint:getY())
    retPoint = DataProcessing.rotateAroundPoint(firstPoint, retPoint, deg)
    return retPoint
  elseif DataProcessing.checkEdgeLength(edgeLength, 3) then
    local deg = (alpha+utils.predefinedAngle[3])
    local retPoint = Point.create(firstPoint:getX() + utils.predefinedSideLengths[1], firstPoint:getY())
    retPoint = DataProcessing.rotateAroundPoint(firstPoint, retPoint, deg)
    return retPoint
  else
    print("Falsche Kantenlänge")
    return nil
  end
end

--@translatePositivePoint(originPoint:Point,vec:Point) : Point
function DataProcessing.translatePositivePoint(originpoint,vec)
  originpoint = originpoint:add(vec)
  return originpoint
end

--@translateNegativePoint(originPoint:Point,vec:Point) : Point
function DataProcessing.translateNegativePoint(originpoint,vec)
  Point.setXY(vec, Point.getX(vec) * (-1), Point.getY(vec) * (-1) )
  originpoint = originpoint:add(vec)
  return originpoint
end

--@computeAngle(p1Scan1:Point, p1Scan2:Point, p2Scan1:Point, p2Scan2:Point) : number
function DataProcessing.computeAngle(p1Scan1, p1Scan2, p2Scan1, p2Scan2)
  local zero = Point.create(0, 0, 0)
  p2Scan1 = DataProcessing.translateNegativePoint(p2Scan1, p1Scan1)
  p2Scan2 = DataProcessing.translateNegativePoint(p2Scan2, p1Scan2)
  local denominator = Point.getDistance(p2Scan1, zero) * Point.getDistance(p2Scan2, zero)
  local angle = math.deg(math.acos(((p2Scan1:getX() * p2Scan2:getX()) + (p2Scan1:getY() * p2Scan2:getY())) / denominator))
  return angle
end

--@computeMatrix(p1Scan1:Point, p2Scan1:Point, angle:number):Matrix
function DataProcessing.computeMatrix(p1Scan1, p1Scan2, angle)
  local m1 = Matrix.create(3, 3)
  m1:setAll(0)
  m1:setValue(0, 0, 1)
  m1:setValue(1, 1, 1)
  m1:setValue(2, 2, 1)
  m1:setValue(0, 2, Point.getX(p1Scan1))
  m1:setValue(1, 2, Point.getY(p1Scan1))

  local m2 = Matrix.create(3, 3)
  m2:setAll(0)
  m2:setValue(0, 0, 1)
  m2:setValue(1, 1, 1)
  m2:setValue(2, 2, 1)
  m2:setValue(0, 2, -Point.getX(p1Scan2))
  m2:setValue(1, 2, -Point.getY(p1Scan2))

  local m3 = Matrix.create(3, 3)
  m3:setAll(0)
  m3:setValue(0, 0, math.cos(math.rad(-angle)))
  m3:setValue(0, 1, -math.sin(math.rad(-angle)))
  m3:setValue(1, 0, math.sin(math.rad(-angle)))
  m3:setValue(1, 1, math.cos(math.rad(-angle)))
  m3:setValue(2, 2, 1)

  local m4 = Matrix.multiply(m2, m3)
  local m5 = Matrix.multiply(m4, m1)

  return m5
end

--@getMatrix(p1Scan1: Point, p1Scan2: Point, angle: number): Matrix, Matrix, Matrix
function DataProcessing.getMatrix(p1Scan1, p1Scan2, angle)
  local m1 = Matrix.create(3, 3)
  m1:setAll(0)
  m1:setValue(0, 0, 1)
  m1:setValue(1, 1, 1)
  m1:setValue(2, 2, 1)
  m1:setValue(0, 2, Point.getX(p1Scan2))
  m1:setValue(1, 2, Point.getY(p1Scan2))

  local m2 = Matrix.create(3, 3)
  m2:setAll(0)
  m2:setValue(0, 0, math.cos(math.rad(-angle)))
  m2:setValue(0, 1, -math.sin(math.rad(-angle)))
  m2:setValue(1, 0, math.sin(math.rad(-angle)))
  m2:setValue(1, 1, math.cos(math.rad(-angle)))
  m2:setValue(2, 2, 1)

  local m3 = Matrix.create(3, 3)
  m3:setAll(0)
  m3:setValue(0, 0, 1)
  m3:setValue(1, 1, 1)
  m3:setValue(2, 2, 1)
  m3:setValue(0, 2, -Point.getX(p1Scan1))
  m3:setValue(1, 2, -Point.getY(p1Scan1))

  return m1,m2,m3
end

--@calculateCalibration(cloud: PointClouds):Array, PointCloud
function DataProcessing.calculateCalibration(cloud)
  
  cloud = DataProcessing.removePointsBeyond(cloud, utils.cutOffDistance)
  local firstPoint, firstPointIndex, secondPoint, secondPointIndex, distance, thirdPoint2D, thirdPointIndex, secondDistance
    = DataProcessing.getCornersAndEdgeLengths(cloud)
  
  cloud:setIntensity({firstPointIndex, secondPointIndex, thirdPointIndex}, 0.3)
  
  if thirdPoint2D == nil then
    thirdPoint2D = DataProcessing.getThirdCorner(firstPoint, secondPoint)
  end

  local thirdPoint = Point.create(thirdPoint2D:getX(), thirdPoint2D:getY(), 0)
  local firstX, firstY = firstPoint:getXY()
  local secondX, secondY = secondPoint:getXY()
  local thirdX, thirdY = thirdPoint:getXY()
  local d1 = Point.create(firstX, firstY, 76)
  local d2 = Point.create(secondX, secondY, 76)
  local d3 = Point.create(thirdX, thirdY, 76)
  local d4 = Point.create(firstX,firstY, 0)
  local d5 = Point.create(secondX, secondY, 0)
  local d6 = Point.create(thirdX, thirdY, 0)
  local points = {d1,d2,d3,d1,d4,d5,d6,d4,d5,d2,d3,d6}

  --Save to global
  if (utils.masterActive == true and utils.slaveActive == false) then
    if DataProcessing.checkEdgeLength(distance,1) then
      utils.masterPoint1 = firstPoint
      utils.masterPoint2 = secondPoint
      utils.masterPoint3 = thirdPoint
    elseif DataProcessing.checkEdgeLength(distance,2) then
      utils.masterPoint2 = firstPoint
      utils.masterPoint3 = secondPoint
      utils.masterPoint1 = thirdPoint
    elseif DataProcessing.checkEdgeLength(distance,3) then
      utils.masterPoint3 = firstPoint
      utils.masterPoint1 = secondPoint
      utils.masterPoint2 = thirdPoint
    end
  end

  if (utils.masterActive == false and utils.slaveActive == true) then
    if DataProcessing.checkEdgeLength(distance,1) then
      utils.slavePoint1 = firstPoint
      utils.slavePoint2 = secondPoint
      utils.slavePoint3 = thirdPoint
    elseif DataProcessing.checkEdgeLength(distance,2) then
      utils.slavePoint2 = firstPoint
      utils.slavePoint3 = secondPoint
      utils.slavePoint1 = thirdPoint
    elseif DataProcessing.checkEdgeLength(distance,3) then
      utils.slavePoint3 = firstPoint
      utils.slavePoint1 = secondPoint
      utils.slavePoint2 = thirdPoint
    end
  end
  
  print(
    "FirstPoint            X:", firstX, "Y:", firstY,
    "\nSecondPoint           X:", secondX, "Y:", secondY,
    "\nCalculated ThirdPoint X:", thirdX, "Y:", thirdY,
    "\nEdge Lengths:", distance, secondDistance)
  
  cloud:setIntensity({firstPointIndex, secondPointIndex, thirdPointIndex}, 0.3)
  return cloud, points
end

return DataProcessing