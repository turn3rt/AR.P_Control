//
//  ViewController.swift
//  AR.P Control
//
//  Created by Turner Thornberry on 1/7/20.
//  Copyright © 2020 Turner Thornberry. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {

    // MARK: - Internal Vars
    // Prompts user to find planes
    let coachingOverlay = ARCoachingOverlayView()
    var focusSquare = FocusSquare()
    var modelOriginPoint = SCNVector3()
    
    // Because I'm lazy
    let updateQueue = DispatchQueue.main
    let userDefaults = UserDefaults.standard
    
    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()//named: "art.scnassets/ship.scn")!
        
        // Set the scene to the view
        sceneView.scene = scene
        
        setupCoachingOverlay()
        setActivatesAutomatically()
        setGoal()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // FOCUS SQUARE
    func updateFocusSquare() {
           if coachingOverlay.isActive {
               focusSquare.hide()
           } else {
               focusSquare.unhide()
           }
           
           // Perform ray casting only when ARKit tracking is in a good state.
           if let camera = sceneView.session.currentFrame?.camera, case .normal = camera.trackingState,
               let query = sceneView.getRaycastQuery(),
               let result = sceneView.castRay(for: query).first {
               
               updateQueue.async {
                   self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
                   self.focusSquare.state = .detecting(raycastResult: result, camera: camera)
               }
           } else {
               updateQueue.async {
                   self.focusSquare.state = .initializing
                   self.sceneView.pointOfView?.addChildNode(self.focusSquare)
               }
           }
       }
    
}



// MARK: - Coaching Overlay Delegate
extension ViewController: ARCoachingOverlayViewDelegate {
    // https://developer.apple.com/documentation/arkit/placing_objects_and_handling_3d_interaction
    func setupCoachingOverlay() {
        // Set up coaching view
        coachingOverlay.session = sceneView.session
        coachingOverlay.delegate = self
        
        coachingOverlay.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(coachingOverlay)
        
        NSLayoutConstraint.activate([
            coachingOverlay.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            coachingOverlay.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            coachingOverlay.widthAnchor.constraint(equalTo: view.widthAnchor),
            coachingOverlay.heightAnchor.constraint(equalTo: view.heightAnchor)
            ])
        
        setActivatesAutomatically()
        setGoal()
    }
    
    // - Tag: CoachingActivatesAutomatically
    func setActivatesAutomatically() {
        coachingOverlay.activatesAutomatically = true
    }

    // - Tag: CoachingGoal
    func setGoal() {
        coachingOverlay.goal = .horizontalPlane
    }
}

// MARK: - AR Delegates
extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    // This executes every time user moves camera
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
           // if !self.hasShownTrunk {
                self.updateFocusSquare()
            //}
        }
    }
}


// Used to translate a 2d point to 3d space plane
extension ARSCNView {
    
//     Type conversion wrapper for original `unprojectPoint(_:)` method.
//     Used in contexts where sticking to SIMD3<Float> type is helpful.

    func unprojectPoint(_ point: SIMD3<Float>) -> SIMD3<Float> {
        return SIMD3<Float>(unprojectPoint(SCNVector3(point)))
    }
    
    // - Tag: CastRayForFocusSquarePosition
    func castRay(for query: ARRaycastQuery) -> [ARRaycastResult] {
        return session.raycast(query)
    }

    // - Tag: GetRaycastQuery
    func getRaycastQuery(for alignment: ARRaycastQuery.TargetAlignment = .any) -> ARRaycastQuery? {
        return raycastQuery(from: screenCenter, allowing: .estimatedPlane, alignment: alignment)
    }
    
    var screenCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
}
