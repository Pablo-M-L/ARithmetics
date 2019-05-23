//
//  Extensions.swift
//  ARithmetics
//
//  Created by admin on 22/05/2019.
//  Copyright © 2019 admin. All rights reserved.
//

import Foundation
extension Int{
    
    //comprueba si los digitos son iguales o no, ya que en el juego no tenemos dos imagenes de un mismo numero.
    var hasUniqueDigits : Bool{
        let strValue = String(self)
        //en un conjunto no puede haber dos elementos iguales.
        let uniqueCharts = Set(strValue)

        return uniqueCharts.count == strValue.count
        
    }
}
