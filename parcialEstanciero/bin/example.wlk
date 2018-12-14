class FaltaDinero inherits Exception { }
class Jugador{
	var property dinero
	var propiedades = []
	var property casilleroActual


    method agregarPropiedad(propiedad){propiedades.add(propiedad)}
    method sacarPropiedad(propiedad){propiedades.remove(propiedad)}
    method agregarDinero(cant){dinero += cant}
    method sacarDinero(cant){dinero -= cant}
    method cantEmpresas(){return propiedades.count({propiedad => propiedad.tipo() == "empresa"})}

	method pagar(entidad,cant){
		if (self.dinero() > cant){
			entidad.agregarDinero(cant)
			self.sacarDinero(cant)	
		}else{
			throw new FaltaDinero ("No alcanza el dinero")
		}		
	}

	
	method generarTransaccion(propiedad,personaje){
		if (personaje!=self){
            personaje.pagar(self,propiedad.renta(self.tirarDado(),self.cantEmpresas()))
            //solo paga la renta si no es el banco
        }
	}

	method tieneTodaLaPronvincia(provincia){
		return provincia.campos().all({campo => campo.duenio() == self})
	}
	
	method construyeEnFormaPareja(provincia){
		return (provincia.maximo() - provincia.minimo()) <= 1
	}
	
	method puedeConstruir(provincia){
		return self.tieneTodaLaPronvincia(provincia) and self.construyeEnFormaPareja(provincia)
	}

	method construirEstancia(campo){ //llega un campo, y tomamos la pronvicia del mismo para analizar todos
		if (self.puedeConstruir(campo.provincia())){ 
			campo.construir()	
			self.sacarDinero(campo.costoProduccion())
		}
	}
	method tirarDado(){
		return 1.randomUpTo(6)
	}


	method moverSobre(listaCasilleros){
		listaCasilleros.forEach({casillero=>casillero.paso(self)})	
		listaCasilleros.last().cayoAqui(self)
		casilleroActual = listaCasilleros.last()
	}
}

object banco inherits Jugador{ 
    override method generarTransaccion(propiedad,personaje){
            if (personaje!=self){
                personaje.pagar(self,propiedad.precio())
                personaje.agregarPropiedad(propiedad)
            }
        }
}

object tablero{
	var lstCasilleros=[]
	method agregarCasillero(entidad){
		lstCasilleros.add(entidad)
	}
	method posicionActual(personaje){
		return personaje.casilleroActual().posicion()
	}
	method agarrarDesdeEstaPosicion(personaje){
		return lstCasilleros.filter({casilleros=>casilleros.posicion() >= self.posicionActual(personaje)})
	}
	method jugar(personaje){
		personaje.moverSobre(self.agarrarDesdeEstaPosicion(personaje).take(personaje.tirarDado()))
	}
}



class Casilleros{
	var property posicion
	method paso(personaje){}
	method cayoAqui(personaje){}
}

class Propiedades inherits Casilleros{
	var property precio
	var property duenio = banco
	var property tipo //recibe el string "empresa" o "campo"
	//simplemente lo uso para el metodo cantEmpresas. Lo use asi para
	//que sea mas simple el metodo
	override method cayoAqui(personaje){
		duenio.generarTransaccion(self,personaje)
	}
	
}

class Campo inherits Propiedades{
	var property rentaFija 
	var property provincia
	var property costoConstruccion
	var property cantEstancias = 0
	var property tipoCampo //recibe el objecto normal o loco, de esta forma diferenciamos los 2 tipos
	
	method renta(_A,_B){ //no me importan los parametros en este caso
		return (2 ** cantEstancias) * rentaFija
	}
	method construir(){cantEstancias ++}
		
}

object normal inherits Campo{}
object loco inherits Campo{
	override method renta(_A,_B){
		return super(_A,_B) * 1.20
	}
	override method paso(jugador){
		if (jugador.cantEmpresas()>5){
			jugador.pagar(self.duenio(),500)	
		}
	}
}

class Empresa inherits Propiedades{
	
	method renta(dado,cantEmpresas){
		return dado * 30000 * cantEmpresas
	}
}

class Premios inherits Casilleros {
	override method cayoAqui(personaje){
		personaje.agregarDinero(2500)
	}
}
class Salidas inherits Casilleros{
	override method paso(personaje){
		personaje.agregarDinero(5000)
	}
}


class Provincia{
	var property campos = []	
	method agregar(campo){campos.add(campo)}
	
	method listaEstancias(){ //lista con la cantidad de estancias por cada campo
		return campos.map({campo => campo.cantEstancias()})
	}
	method propietarios(){return campos.map({campo => campo.duenio()})}
	
	method maximo(){return self.listaEstancias().max()}
	method minimo(){return self.listaEstancias().min()}
	//Saco maximo y minimo, ya que si al diferencia entre el maximo y el minimo es 1, entonces construye de forma pareja
	// Ya que si entre los maximos y minimos es 1, entre el resto tambien va a ser 1 o menor a 1
}



