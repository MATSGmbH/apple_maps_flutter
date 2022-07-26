//
//  PolylineController.swift
//  apple_maps_flutter
//
//  Created by Luis Thein on 12.11.19.
//

import Foundation
import MapKit

extension AppleMapController: PolylineDelegate {
    
    func polylineRenderer(overlay: MKOverlay) -> MKOverlayRenderer {
        // Make sure we are rendering a polyline.
        guard let polyline = overlay as? MKPolyline else {
           return MKOverlayRenderer()
        }
        
        if let flutterPolyline: FlutterPolyline = overlay as? FlutterPolyline {
            if #available(iOS 14.0, *),
               let gradientColors = flutterPolyline.gradientColors,
               !gradientColors.isEmpty,
               gradientColors.count == flutterPolyline.pointCount {
                let gradientRenderer = MKGradientPolylineRenderer(overlay: polyline)
                gradientRenderer.strokeColor = flutterPolyline.color
                gradientRenderer.lineWidth = flutterPolyline.width ?? 1.0
                gradientRenderer.lineDashPattern = flutterPolyline.pattern
                gradientRenderer.lineJoin = flutterPolyline.lineJoin!
                gradientRenderer.lineCap = flutterPolyline.capType!
                gradientRenderer.setColors(flutterPolyline.gradientColors!, locations: flutterPolyline.locations(at: IndexSet(integersIn: Range(NSMakeRange(0, flutterPolyline.pointCount))!)))
                return gradientRenderer
            }
            else if flutterPolyline.isVisible! {
                let polylineRenderer = MKPolylineRenderer(overlay: polyline)
                polylineRenderer.strokeColor = flutterPolyline.color
                polylineRenderer.lineWidth = flutterPolyline.width ?? 1.0
                polylineRenderer.lineDashPattern = flutterPolyline.pattern
                polylineRenderer.lineJoin = flutterPolyline.lineJoin!
                polylineRenderer.lineCap = flutterPolyline.capType!
                return polylineRenderer
            } else {
                let polylineRenderer = MKPolylineRenderer(overlay: polyline)
                polylineRenderer.strokeColor = UIColor.clear
                polylineRenderer.lineWidth = 0.0
                return polylineRenderer
            }
        }
        return MKPolylineRenderer(overlay: polyline)
    }

    func addPolylines(polylineData data: NSArray) {
        for _polyline in data {
            let polylineData :Dictionary<String, Any> = _polyline as! Dictionary<String, Any>
            let polyline = FlutterPolyline(fromDictionaray: polylineData)
            addPolyline(polyline: polyline)
        }
    }

    func changePolylines(polylineData data: NSArray) {
        let oldOverlays: [MKOverlay] = self.mapView.overlays
        for oldOverlay in oldOverlays {
            if oldOverlay is FlutterPolyline {
                let oldFlutterPolyline = oldOverlay as! FlutterPolyline
                for _polyline in data {
                    let polylineData :Dictionary<String, Any> = _polyline as! Dictionary<String, Any>
                    if oldFlutterPolyline.id == (polylineData["polylineId"] as! String) {
                        let newPolyline = FlutterPolyline.init(fromDictionaray: polylineData)
                        if oldFlutterPolyline != newPolyline {
                            updatePolylinesOnMap(oldPolyline: oldFlutterPolyline, newPolyline: newPolyline)
                        }
                    }
                }
            }
        }
    }

    func removePolylines(polylineIds: NSArray) {
        for overlay in self.mapView.overlays {
            if let polyline = overlay as? FlutterPolyline {
                if polylineIds.contains(polyline.id!) {
                    self.mapView.removeOverlay(polyline)
                }
            }
        }
    }
    
    func removeAllPolylines() {
        for overlay in self.mapView.overlays {
            if let polyline = overlay as? FlutterPolyline {
                self.mapView.removeOverlay(polyline)
            }
        }
    }
    
    private func updatePolylinesOnMap(oldPolyline: FlutterPolyline, newPolyline: FlutterPolyline) {
        self.mapView.removeOverlay(oldPolyline)
        addPolyline(polyline: newPolyline)
    }
    
    private func addPolyline(polyline: FlutterPolyline) {
        if polyline.zIndex == nil || polyline.zIndex == -1 {
            self.mapView.addOverlay(polyline)
        } else {
            self.mapView.insertOverlay(polyline, at: polyline.zIndex ?? 0)
        }
    }
    
    private func linePatternToArray(patternData: NSArray?, lineWidth: CGFloat?) -> [NSNumber] {
        var finalPattern: [NSNumber] = []
        var isDot: Bool = false
        if patternData == nil {
            return finalPattern
        }
        for pattern in patternData! {
            if let _pattern: NSArray = pattern as? NSArray {
                if _pattern.count > 0 {
                    if let identifier: String = _pattern[0] as? String {
                        if identifier == "dot" {
                            isDot = true
                            finalPattern.append(0)
                        } else if identifier == "dash" {
                            isDot = false
                            finalPattern.append(NSNumber(value: lround((_pattern[1] as! Double) * 1/3.5)))
                        } else if identifier == "gap" {
                            if let length = _pattern[1] as? Double {
                                if isDot {
                                    finalPattern.append(NSNumber(value: lround(Double((lineWidth ?? 0) * 1.5))))
                                } else {
                                    finalPattern.append(NSNumber(value: lround(length * 1/3.5)))
                                }
                            }
                        }
                    }
                }
            }
        }
        return finalPattern
    }
    
    private func getLineCapForLinePattern(linePatternData: NSArray?) -> CGLineCap {
        if linePatternData == nil {
            return CGLineCap.butt
        }
        for pattern in linePatternData! {
            if let _pattern = pattern as? NSArray {
                if _pattern.contains("dot") {
                    return CGLineCap.round
                } else if _pattern.contains("dash") {
                    return CGLineCap.butt
                }
            }
        }
        return CGLineCap.butt
    }
}
