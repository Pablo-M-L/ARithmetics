//
//  ViewController.swift
//  ARithmetics
//
//  Created by admin on 21/05/2019.
//  Copyright © 2019 admin. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

// enumerado con las posibles operaciones disponibles.
// con casiterable obtenemos una operacion de forma aleatoria.
enum MathOperation: CaseIterable{
    case add, subtract, multiply, divide
}


class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var correctImageView: UIImageView!
    
    var correctAnswer : Int? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        askQuestion()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        

        // referencia a el metodo de imagen de referencia, indicando el grupo donde estan las imagenes.
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Numbers", bundle: nil) else{
            //si no encuentra las imagenes salta un fatalerror
            fatalError("no se ham podido cargar las imagenes par aAR...")
        }
        
        // signamos el conjuntos de imagenes generado en el guard let.
        configuration.trackingImages = trackingImages
        
        //maximo numero de imagenes trackeadas.
        configuration.maximumNumberOfTrackedImages = 2 //por defecto es 1
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    

    // Override to create and configure nodes for anchors added to the view's session.
    
    //este metodo se llama cuando se detecta un ancla. un ancla es cada objeto trackeable.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
     
        //el anchor recibido como parametro lo convertimos en un ancla de imagen y lo guardamos en la constante.
        //encima del imageAnchor colocamos la imagen.
        guard let imageAnchor = anchor as? ARImageAnchor else{
            return nil
        }
        
        //creamos el plano con la anchura y altura de la imagen de referencia.
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        
        //pinta el material del plano, de verde pero con algo de transparencia.
        plane.firstMaterial?.diffuse.contents = UIColor.green.withAlphaComponent(0.4)
        
        //creamos un nodo a partir del plano. que será colocado sobre la imagen.
        let planeNode = SCNNode(geometry: plane)
        
        //rotamos la imagen para que quede plana.
        planeNode.eulerAngles.x = -.pi/2
        
        //ya tenemos el plano y lo hemos "aplanado"
        //ahora creamos el node vacio y le añadimos el hijo
        let node = SCNNode()
        //el hijo servira para observar los cuadrados verdes sobre las imagenes. 
        node.addChildNode(planeNode)
     
        return node
    }

    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
    
    // MARK: game methos
    
    //crea la pregunta y la respuesta
    func createNewQuestion() -> (question: String, answer: Int){
        let operation = MathOperation.allCases.randomElement()!
        var question : String
        var answer : Int
        
        repeat{
            
            switch operation{
            case .add:
                let x = Int.random(in: 1...49)
                let y = Int.random(in: 1...49)
                question = "\(x) + \(y) = ? "
                answer = x + y
                
            case .subtract:
                let x = Int.random(in: 1...49)
                let y = Int.random(in: 1...49)
                let min = x < y ? x : y
                let max = x < y ? y : x
                question = "\(max) - \(min) = ? "
                answer = max - min
                
            case .multiply:
                let x = Int.random(in: 1...10)
                let y = Int.random(in: 1...9)
                question = "\(x) x \(y) = ? "
                answer = x * y
                
            case .divide:
                var x: Int
                var y: Int
                var restoCero: Int
                var max: Int
                var min: Int
                repeat{
                    x = Int.random(in: 1...49)
                    y = Int.random(in: 1...49)
                    min = x < y ? x : y
                    max = x < y ? y : x
                    restoCero = max % min
                    }while restoCero != 0

                answer = max / min
                question = "\(max) / \(min) = ? "
            }
        }while  !answer.hasUniqueDigits
        
        return (question, answer)
        
    }
    
    //muestra la pregunta, asigna la respuesta.
    func askQuestion(){
        let newQuestion = createNewQuestion()
        questionLabel.text = newQuestion.question
        correctAnswer = newQuestion.answer
        
        questionLabel.alpha = 0
        UIView.animate(withDuration: 0.7) {
            self.questionLabel.alpha = 1.0
            
            self.correctImageView.alpha = 0.0
            self.correctImageView.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
        }
    }
    
    func showCorrectAnswer(){
        correctImageView.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
        
        UIView.animate(withDuration: 0.7) {
            self.correctImageView.transform = .identity
            self.correctImageView.alpha = 1.0
        }
        
        //en lugar de un timere se usa un segundo hilo llamado despues de 1,2 segundos desde el momento en el que se le llama.
        DispatchQueue.main.asyncAfter(deadline: .now()+3) {
            self.askQuestion()
        }
        
    }
    
    //update de scene kit -> se llama a cada frame de actualizacion. 60 frames por segundo.
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        //obtener la lista de anclas que hay actualmente en la pantalla.
        guard let anchor = sceneView.session.currentFrame?.anchors else {return}
       // print(anchor.count)
        
        //filtrar las anclas que son imagenes y elminar las que no sean imagenes o las que no estan en un grupo de arkit.
        let visibleAnchors = anchor.filter {
            guard let anchor = $0 as? ARImageAnchor else{return false}
            return anchor.isTracked
        }
        
        
        //ordenar la lista de anclas imagenes visibles de izquierda a derecha por su poscion en x.
        let nodes = visibleAnchors.sorted{ (anchor1, anchor2) -> Bool in
            guard let node1 = sceneView.node(for: anchor1) else {return false}
            guard let node2 = sceneView.node(for: anchor2) else { return false}
            
            return node1.worldPosition.x < node2.worldPosition.x
        }
        
        
        //de las imagenes extraeremos sus nombres y de ahi los numero para juntarlos en un string.
        //reduce es un bucle.
        let strAnswer = nodes.reduce("") { $0  + ($1.name ?? "")  }
        
        
        //convertiremos el string a entero
        let userAnswer = Int(strAnswer) ?? 0
        //print(userAnswer)
        
        
        //comprobar si el entero es la repuesta correcta para llamar al metodo de showCorrectAnswer.
        if userAnswer == correctAnswer{
            //anulamos la respuesta actual para evitar problemas en el proximo frame.
            correctAnswer = nil
            //traemos el check verde.
            DispatchQueue.main.asyncAfter(deadline: .now()+0.5) {
                self.showCorrectAnswer()
            }
        }
        
    }
}
