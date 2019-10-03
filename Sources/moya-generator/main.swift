import Foundation
import Commander
import FileUtils


func generate(inputFile: String, outputPath: String) {
    guard File.exists(inputFile) else {
        print("File not found")
        return
    }
    
    do {
        let content = try File.read(atPath: inputFile)
        guard let data = content.data(using: .utf8) else {
            print("Couldn't read data")
            return
        }
        
        let decoder = JSONDecoder()
        let config = try decoder.decode(Config.self, from: data)
        print("1")
        
        var destinationFolder = outputPath
        destinationFolder.append("/Providers/")
        Directory.create(atPath: destinationFolder)
        destinationFolder.append("\(config.providerName)/")
        Directory.create(atPath: destinationFolder)
        
        print("2 \(destinationFolder)")
        
        let generatedProviderContent = Generator.generateProvider(from: config)
        let providerDestination = destinationFolder + config.providerName + ".swift"
        
        let generatedModelsContent = Generator.generateModels(from: config)
        let modelsDestination = destinationFolder + config.providerName + "Models.swift"
        
        print("3")
        
        print("providerDestination \(providerDestination)")
        print("modelsDestination \(modelsDestination)")
        
        guard (config.custom ?? false) else {
            try File.write(string: generatedProviderContent, toPath: providerDestination)
            try File.write(string: generatedModelsContent, toPath: modelsDestination)
            return
        }
        
        print("4")
                
        if !File.exists(providerDestination) {
            try File.write(string: generatedProviderContent, toPath: providerDestination)
        }
        
        print("5")
        if !File.exists(modelsDestination) {
            try File.write(string: generatedModelsContent, toPath: modelsDestination)
        }
        
    } catch {
        print("error \(error)")
    }
}

command(
  Option("inputPath", default: ""),
  Option("outputPath", default: "")
) { inputPath, outputPath in
    print("Reading path: \(inputPath)")
    print("Output path: \(outputPath)")
    
    let (files, _) = Directory.contents(ofDirectory: inputPath)!
    files.forEach { (inputFile) in
        print("inputFile \(inputPath + "/" + inputFile)")
        generate(inputFile: inputPath + "/" + inputFile, outputPath: outputPath)
    }
    
}.run()
