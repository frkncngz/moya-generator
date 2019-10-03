import Foundation
import Commander
import FileUtils

let main = command { (filename:String) in
    print("Reading file: \(filename)")
        
    var path = Path.currentDirectory
    path.append("/" + filename)
    print("path \(path)")
    guard File.exists(path) else {
        print("File not found")
        return
    }
    
    do {
        let content = try File.read(atPath: path)
        guard let data = content.data(using: .utf8) else {
            print("Couldn't read data")
            return
        }
        
        let decoder = JSONDecoder()
        let config = try decoder.decode(Config.self, from: data)
        
        var destinationFolder = Path.currentDirectory
        destinationFolder.append("/Providers/\(config.providerName)/")
        Directory.create(atPath: destinationFolder)
        
        let generatedProviderContent = Generator.generateProvider(from: config)
        let providerDestination = destinationFolder + config.providerName + ".swift"
        
        let generatedModelsContent = Generator.generateModels(from: config)
        let modelsDestination = destinationFolder + config.providerName + "Models.swift"        
        
        guard (config.custom ?? false) else {
            try File.write(string: generatedProviderContent, toPath: providerDestination)
            try File.write(string: generatedModelsContent, toPath: modelsDestination)
            return
        }
                
        if !File.exists(providerDestination) {
            try File.write(string: generatedProviderContent, toPath: providerDestination)
        }
        if !File.exists(modelsDestination) {
            try File.write(string: generatedModelsContent, toPath: modelsDestination)
        }
        
    } catch {
        print("error \(error)")
    }
}

main.run()
