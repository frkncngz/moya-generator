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
        let generatedFileContent = Generator.generate(from: config)
        
        var destination = Path.currentDirectory
        destination.append("/" + config.providerName + ".swift")
        try File.write(string: generatedFileContent, toPath: destination)
    } catch {
        print("error \(error)")
    }
}

main.run()
