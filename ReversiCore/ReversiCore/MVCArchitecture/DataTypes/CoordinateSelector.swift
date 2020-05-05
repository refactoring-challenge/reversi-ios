import Hydra


// NOTE: Given available coordinates must not be empty because the only possible way is pass if no coordinates are available.
typealias CoordinateSelector = (NonEmptyArray<AvailableCoordinate>) -> Hydra.Promise<AvailableCoordinate>
