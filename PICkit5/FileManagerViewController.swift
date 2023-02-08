//
//  FileManagerViewController.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/3.
//

import UIKit

class FileManagerViewController: UIViewController, bleUARTCallBack, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate{
    
    @IBOutlet weak var BrowseSDButton: UIButton!
    @IBOutlet weak var SearchFilter: UITextField!
    
    var bleUart : bleUART?
    
    var SelectedFile : String!
     
    var PTGLastSelected : String!
    
    var SelectedPeripheral : String!

    var FilterPTGDone : Bool = false
    
    var PTGFolders = [String]()
     
    var FilterPTGFolders = [String]()
    
    var PTGButton: UIBarButtonItem!
    
    var HideBackButton = true
    
    var BrowseSDCardPath = Data()
    
    var KeyboardIsAlive = false
    
    var PTGActiveFile = ""
    
    var ActivePTG_Directory_Path = Data()
    
    enum PTGDisplayMode{
        case All
        case Image
        case Folder
    }
    var PTGDisplay: PTGDisplayMode = .All
    
    var PTGState = PICkit_OpCode.BLE_PTG_UNINIT{
        didSet{
            print("PTGState chabged!new state = \(PTGState)")
            PTGStateChange(state: PTGState)
        }
    }
    
    var tap : UITapGestureRecognizer? = nil

    @IBOutlet weak var SDCardFileListTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        print("[FileManagerViewController]viewDidLoad")
        
        self.title = "File Manager"
        
        print("Selected peripheral = \(self.SelectedPeripheral ?? "")")
        
        #if !targetEnvironment(simulator)
            if bleUart == nil{
                bleUart = bleUART.sharedInstace(option: .Normal)
            }
            self.PTGState = .BLE_PTG_INIT
        #else
            FilterPTGFolders.append("PIC32CX_001.ptg")
            FilterPTGFolders.append("PIC32CX_002.ptg")
            FilterPTGFolders.append("PIC32CX_003.ptg")
        #endif
        
        SDCardFileListTable.delegate = self
        SDCardFileListTable.dataSource = self
        
        SDCardFileListTable.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        
        SearchFilter.delegate = self
        SearchFilter.returnKeyType = .search
        
        self.navigationItem.rightBarButtonItem = PTGButton
        
        BackToRootDirectory()
        
        //BrowseSDButton.isEnabled = false
        BrowseSDButton.isEnabled = true
        BrowseSDButton.setTitleColor(.white, for: .normal)
        BrowseSDButton.backgroundColor = UIColor(red: 0.96, green: 0.55, blue: 0.17, alpha: 1.00)//#f68d2c
        
        self.view.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.isNavigationBarHidden = false
        
        #if !targetEnvironment(simulator)
            bleUart?.callback = self
        #endif
        
        SearchFilter.text = ""
        
        FilterPTGDone = false
        
        print("[viewWillAppear] Selected PTG = \(self.SelectedFile ?? "")")
        
        print("PTGActiveFile = \(self.PTGActiveFile)")
        
        GetFilePath(ptgName: self.PTGActiveFile)
        
        print("LastSelected = \(self.PTGLastSelected)")
        
        //print("Selected peripheral = \(self.SelectedPeripheral ?? "")")
        print("[FileManagerVC]Selected peripheral = \(self.SelectedPeripheral ?? "")")
        
        self.SDCardFileListTable.reloadData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if(isMovingFromParent){
            print("[FileManagerVC]Back button detected!")
            //print("\(activityIndicator?.isAnimating)")
            
            self.performSegue(withIdentifier: "FileManagerDidSelectPTG", sender: self)
        }
    }
    
    func BLE_PTG_INIT(){
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_INIT, commandData: Data(), completion: {(error)in
            if error != nil{
                //print("BLE PTG INIT ")
                print("Error = \(error ?? "")")
                if((error?.contains("/")) != nil){
                    let errors = error?.split(separator: "/")
                    if(errors?.count == 2){
                        self.PICkit_Custom_Alert(title: String(errors![0]), content: String(errors![1]), oneButton: true, image: "error")
                    }
                }
            }
            else{
                print("Process BLE PTG INIT: Success")
                self.PTGState = .BLE_PTG_INIT
            }
        })
    }
    
    func BLE_PTG_BROWSE_SD_CARD(SDCardPath: Data){
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_BROWSE_SD_CARD, commandData: SDCardPath, completion: {(error)in
            if error != nil{
                print("BLE PTG BROWSE_SD_CARD : Error = \(error ?? "")")
                if((error?.contains("/")) != nil){
                    let errors = error?.split(separator: "/")
                    if(errors?.count == 2){
                        self.PICkit_Custom_Alert(title: String(errors![0]), content: String(errors![1]), oneButton: true, image: "X-icon")
                    }
                }
            }
            else{
                print("Process BLE_PTG_BROWSE_SD_CARD : Success")
                self.PTGState = .BLE_PTG_BROWSE_SD_CARD
            }
        })
    }
    
    func BLE_PTG_LOAD_IMAGE(){
        print("BLE_PTG_LOAD_IMAGE, image name = \(self.SelectedFile ?? "")")
        
        var data: Data?

        let file = self.SelectedFile
        
        data = Data(file!.utf8)
        print("Load file, path = \(file!), \(data! as NSData)")
        
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_LOAD_IMAGE, commandData: data!, completion: {(error)in
            if error != nil{
                print("BLE PTG LOAD IMAGE : Error")
                self.PTGActiveFile = ""
                self.PTGLastSelected = ""
                self.SDCardFileListTable.reloadData()
                /*
                if((error?.contains("/")) != nil){
                    let errors = error?.split(separator: "/")
                    if(errors?.count == 2){
                        
                        let okHandler: ((UIAlertAction) -> Void)? = { (_) in
                            self.BLE_PTG_REINIT()
                        }
                        self.PICkit_Custom_Alert(title: String(errors![0]), content: String(errors![1]), oneButton: true, image: "X-icon", ok_handler: okHandler, cancel_handler: nil)
                    }
                }*/
            }
            else{
                print("Success")
                self.performSegue(withIdentifier: "StatusSegue", sender: self)
            }
        })
    }
    
    func BLE_PTG_REINIT(){
        print(#function)
        bleUart?.PICkit_WriteCommand(commandID: .BLE_PTG_REINIT, commandData: Data(), completion: {(error)in
            if error != nil{
                print("Error = \(error ?? "")")
                if((error?.contains("/")) != nil){
                    let errors = error?.split(separator: "/")
                    if(errors?.count == 2){
                        let okHandler: ((UIAlertAction) -> Void)? = { (_) in
                            self.performSegue(withIdentifier: "FileManagerDidDisconnect", sender: self)
                        }
                        self.PICkit_Custom_Alert(title: String(errors![0]), content: String(errors![1]), oneButton: true, image: "error", ok_handler: okHandler, cancel_handler: nil)
                    }
                }
            }
            else{
                print("Process BLE PTG REINIT: Success")
                self.PTGState = .BLE_PTG_REINIT
            }
        })
    }
    
    func ShowToast(message: String){
        
        let alertView = UIAlertController(style: .alert)
        
        alertView.setViewController(image: UIImage(named: "X-icon")!, title: message, message: "")
        
        present(alertView, animated: true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                alertView.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func PICkit_Custom_Alert(title:String, content: String, oneButton:Bool, image: String, ok_handler: ((UIAlertAction) -> Void)? = nil, cancel_handler: ((UIAlertAction) -> Void)? = nil){
        let alertView = UIAlertController(style: .alert)
        
        alertView.setViewController(image: UIImage(named: image)!, title: title, message: content)
        
        if oneButton{
            alertView.addAlertAction(title: "Ok", style: .default, handler: ok_handler)
        }
        else{
            alertView.addAlertAction(title: "Ok", style: .default, handler: ok_handler)
            alertView.addAlertAction(title: "Cancel", style: .default, handler: cancel_handler)
        }
        present(alertView, animated: true, completion: nil)
    }
    
    func PTGStateChange(state: PICkit_OpCode){
        if state == .BLE_PTG_INIT{
            BrowseSDButton.isEnabled = true
            
            sleep(1)

            BackToRootDirectory()
            
            self.BLE_PTG_BROWSE_SD_CARD(SDCardPath: BrowseSDCardPath)
        }
        else if(state == .BLE_PTG_REINIT){
            self.PTGState = .BLE_PTG_INIT
        }
    }
    
    @objc func TogglePTGDisplay(){
        print(#function)
        if(PTGButton.title == "All"){
            print("PTG All. \(FilterPTGFolders.count),\(PTGFolders.count)")
            if(FilterPTGFolders.count != PTGFolders.count){
                FilterPTGFolders.removeAll()
                FilterPTGFolders = PTGFolders
                SDCardFileListTable.reloadData()
            }
            else{
                PTGButton.title = "Image"
                let str = ".ptg"
                let FilterArray = PTGFolders.filter({$0.lowercased().contains(str.lowercased())})
                if(!FilterArray.isEmpty){
                    FilterPTGFolders.removeAll()
                    FilterPTGFolders = FilterArray
                    self.SDCardFileListTable.reloadData()
                }
            }
        }
        else if(PTGButton.title == "Image"){
            PTGButton.title = "Folder"
            let str = ".ptg"
            let FilterArray = PTGFolders.filter({($0.lowercased().contains(str.lowercased())) == false})
            if(!FilterArray.isEmpty){
                FilterPTGFolders.removeAll()
                FilterPTGFolders = FilterArray
                self.SDCardFileListTable.reloadData()
            }
        }
        else if(PTGButton.title == "Folder"){
            PTGButton.title = "All"
            if(FilterPTGFolders.count != PTGFolders.count){
                FilterPTGFolders.removeAll()
                FilterPTGFolders = PTGFolders
                SDCardFileListTable.reloadData()
            }
        }
    }
    
    func AppendSubDirectory(path : Data){
        if(!BrowseSDCardPath.isEmpty){
            BrowseSDCardPath.append(Data([0x2f]))   // '/'
            BrowseSDCardPath.append(path)
            print("AppendSubDirectory. \(String(decoding: BrowseSDCardPath, as: UTF8.self))")
        }
    }
    
    func DisplaySDCardBrowsePath() -> String?{
        if(!HideBackButton){
            //print(#function)
            var dir = String(decoding: BrowseSDCardPath, as: UTF8.self)
            print(dir)
            let ix = dir.startIndex
            let ix2 = dir.index(ix, offsetBy: 1)
            dir.removeSubrange(ix...ix2)    //Remove 0:
            print("DisplaySDCardBrowsePath. dir = \(dir)")
            return dir
        }
        return nil
    }
    
    func BackToPreviousDirectory(){
        let dir = String(decoding: BrowseSDCardPath, as: UTF8.self)
        let StrArray = dir.split(separator: "/")
        if(!StrArray.isEmpty){
            if let index = dir.lastIndex(of: "/"){
                let newDir = dir[..<index]
                print("BackToPreviousDirectory = \(newDir)")
                BrowseSDCardPath = Data(newDir.utf8)
            }
        }
    }
    
    func BackToRootDirectory(){
        print(#function)
        BrowseSDCardPath = Data([0x30,0x3a])    //"0:"
    }
    
    func GetFilePath(ptgName: String){
        let directoryLevel = ptgName.split(separator: "/")
        if directoryLevel.count >= 2{
            //print(#function)
            //print(directoryLevel)
            if let range = ptgName.range(of: "/" + directoryLevel[directoryLevel.count-1]) {
                let substring = ptgName[..<range.lowerBound]
                print(substring)
                ActivePTG_Directory_Path = Data(substring.utf8)
                print("ActivePTG_Directory_Path = \(ActivePTG_Directory_Path as NSData)")
            }
        }
    }
    
    func IsRootDirectory() -> Bool{
        print("\n")
        print(#function)
        let dir = String(decoding: BrowseSDCardPath, as: UTF8.self)
        print(dir)
        return dir == "0:" ? true : false
    }
    
    @objc func ClickBackButton() {
        print(#function)
            
        if(FilterPTGDone){
            FilterPTGDone = false
            print("PTGListIsChanged! Update PTG list.")
            if(IsRootDirectory()){
                HideBackButton = true
                print("root directory: true")
                FilterPTGFolders.removeAll()
                FilterPTGFolders = PTGFolders
                SDCardFileListTable.reloadData()
            }
            BLE_PTG_BROWSE_SD_CARD(SDCardPath: BrowseSDCardPath)
        }
        else{
            if(!IsRootDirectory()){
                print("false")
                BackToPreviousDirectory()
                if(IsRootDirectory()){
                    HideBackButton = true
                    print("root directory: true. Reload PTG files")
                    FilterPTGFolders.removeAll()
                    FilterPTGFolders = PTGFolders
                    SDCardFileListTable.reloadData()
                    return
                }
            }
            self.BLE_PTG_BROWSE_SD_CARD(SDCardPath: BrowseSDCardPath)
        }
    }
    
    @IBAction func NextSyep(_ sender: Any) {
        //self.performSegue(withIdentifier: "SetupSegue", sender: self)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer){
        print(#function)
        if(KeyboardIsAlive){
            KeyboardIsAlive = false
            self.view.endEditing(true)
            
            if(tap != nil){
                view.removeGestureRecognizer(tap!)
                tap = nil
                SearchFilter.text = ""
            }
        }
    }
    
    @IBAction func PTGFileRefresh(_ sender: Any) {
        //print(#function)
        
        if(KeyboardIsAlive){
            KeyboardIsAlive = false
            self.view.endEditing(true)
            if(tap != nil){
                view.removeGestureRecognizer(tap!)
                tap = nil
                SearchFilter.text = ""
            }
        }
        
        HideBackButton = true
        FilterPTGDone = false
        
        BackToRootDirectory()
        
        PTGFolders.removeAll()
        FilterPTGFolders.removeAll()
        SDCardFileListTable.reloadData()
        
        print("Browse SD card PTG files..")
        
        BLE_PTG_BROWSE_SD_CARD(SDCardPath: BrowseSDCardPath)
    }
    
    // MARK: - TableView delegate
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat{
        return HideBackButton ? 0.1 : 45
        //return 30
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PTGBackButtonCell") as! PTGCustomCell
        
        cell.BackButton.addTarget(self, action: #selector(FileManagerViewController.ClickBackButton), for: .touchDown)
        cell.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        
        if(!IsRootDirectory()){
            if let path = DisplaySDCardBrowsePath(){
                //cell.Path.text = "Root" + path
                cell.Path.text = "0:" + path
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return FilterPTGFolders.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "PTGFile", for: indexPath) as! PTGFileTableViewCell
        
        cell.backgroundColor = UIColor(red: 0.82, green: 0.40, blue: 0.42, alpha: 1.00)//#d0666a
        
        let fileName = FilterPTGFolders[indexPath.row]
        
        if(fileName.lowercased().contains(".ptg".lowercased())){
            cell.PTGImage.image = UIImage(named: "File-icon")
        }
        else{
            cell.PTGImage.image = UIImage(named: "Folder-icon")
        }
        
        cell.PTGFileName.textColor = UIColor.white
        cell.PTGFileName.text = FilterPTGFolders[indexPath.row]
                
        if(self.PTGLastSelected == cell.PTGFileName.text){
            cell.accessoryType = .checkmark
        }
        else{
            let ptgName = cell.PTGFileName.text
            if self.PTGActiveFile.contains(ptgName!){
                if BrowseSDCardPath == ActivePTG_Directory_Path{
                    cell.accessoryType = .checkmark
                }
                else{
                    cell.accessoryType = .none
                }
            }
            else{
                cell.accessoryType = .none
            }
        }
        
        let separatorHeight = CGFloat(5.0)
        let additionalSeparator = UIView.init(frame: CGRect(x: 0, y: cell.contentView.frame.size.height-separatorHeight, width: cell.contentView.frame.width, height: separatorHeight))
        additionalSeparator.backgroundColor = UIColor(red: 0.21, green: 0.71, blue: 0.90, alpha: 1.00)//#36b4e5
        cell.addSubview(additionalSeparator)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? PTGFileTableViewCell{
            if cell.accessoryType == .none{
                cell.accessoryType = .checkmark
            }
            else{
                cell.accessoryType = .none
            }
            if(FilterPTGDone){
                FilterPTGDone = false
            }
            if((cell.PTGFileName.text?.lowercased().contains(".ptg")) == true){
                print("didSelectPTG.\(cell.PTGFileName.text ?? "")")
                self.PTGLastSelected = cell.PTGFileName.text
                self.PTGActiveFile = self.PTGLastSelected
                
                let ptgName = cell.PTGFileName.text
                if(IsRootDirectory()){
                    let file = "0:/" + ptgName!
                    self.SelectedFile = file
                }
                else{
                    let file = String(decoding: BrowseSDCardPath, as: UTF8.self) + "/" + ptgName!
                    self.SelectedFile = file
                }
                
                tableView.deselectRow(at: indexPath, animated: true)
                
                #if !targetEnvironment(simulator)
                    BLE_PTG_LOAD_IMAGE()
                    //self.performSegue(withIdentifier: "StatusSegue", sender: self)//Debug
                #else
                    self.performSegue(withIdentifier: "StatusSegue", sender: self)
                #endif
            }
            else{
                if(cell.PTGFileName.text == "<TRUNCATED>"){
                    cell.accessoryType = .none
                    tableView.deselectRow(at: indexPath, animated: true)
                    return
                }
                
                //print("This is PTG folder.\()")
                self.SelectedFile = cell.PTGFileName.text
                print("This is PTG folder.\(SelectedFile ?? "")")
                
                cell.accessoryType = .none
                
                self.SDCardFileListTable.reloadData()
                
                let fileData = Data(self.SelectedFile.utf8)
                
                AppendSubDirectory(path: fileData)
                
                BLE_PTG_BROWSE_SD_CARD(SDCardPath: BrowseSDCardPath)
            }
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        print("[FileManagerViewController]segue id = \(segue.identifier ?? "")")
        
        if(segue.identifier == "StatusSegue"){
            let vc = segue.destination as! StatusViewController
        
            vc.SelectedPeripheral = self.SelectedPeripheral
            vc.SelectedFile = self.SelectedFile
        }
    }
    
    //MARK: - TextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        print("textFieldDidBeginEditing.\(textField.text ?? "")")
        KeyboardIsAlive = true
        if(tap == nil){
            tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            view.addGestureRecognizer(tap!)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if(textField.returnKeyType == .search) {
            textField.resignFirstResponder()
            print("Search filter = \(textField.text ?? "")")
            
            KeyboardIsAlive = false
            if(tap != nil){
                view.removeGestureRecognizer(tap!)
                tap = nil
            }
                        
            if(FilterPTGFolders.count != 0 && SearchFilter.text != ""){
                if((SearchFilter.text!.contains(" "))){
                    print("Find space")
                    SearchFilter.text = ""
                    return true
                }

                print("Filter PTG files..")
                if let str = SearchFilter.text{
                    let FilterArray = FilterPTGFolders.filter({$0.lowercased().contains(str.lowercased())})
                    if(!FilterArray.isEmpty){
                        let compareSet = Set(FilterArray)
                        let resultArray = FilterPTGFolders.filter{!compareSet.contains($0)}
                        print("resultArray = \(resultArray)")
                        if(!resultArray.isEmpty){
                            HideBackButton = false
                            FilterPTGDone = true
                            FilterPTGFolders.removeAll()
                            FilterPTGFolders = FilterArray
                            SelectedFile = ""
                            self.SDCardFileListTable.reloadData()
                        }
                    }
                    self.SearchFilter.text = ""
                }
            }
            else{
                FilterPTGDone = false
            }
            return true
        }
        else{
            return false
        }
    }
    
    // MARK: - bleUARTCallBack delegate
    func bleDidDisconnect(error:String){

        let okHandler: ((UIAlertAction) -> Void)? = { (_) in
            self.performSegue(withIdentifier: "FileManagerDidDisconnect", sender: self)
        }
        print("bleDidDisconnect, error = \(error)")
        
        self.PICkit_Custom_Alert(title: "BLE disconnected!", content: error, oneButton: true, image: "X-icon", ok_handler: okHandler, cancel_handler: nil)
    }

    func bleProtocolError(title: String, message: String){
        print("[FileManagerVC] bleProtocolError")
        
        self.PICkit_Custom_Alert(title: title, content: message, oneButton: true, image: "X-icon")
    }
    
    func bleCommandResponse(command: UInt8, data: Data){
        print("[FileManagerVC] bleCommandResponse")
        
        if(command == PICkit_OpCode.BLE_PTG_BROWSE_SD_CARD.rawValue){
            if(data.isEmpty){
                print("Data is empty!")
                //ShowToast(message: "Empty folder")
                self.SelectedFile = ""
                self.PTGLastSelected = ""
                BackToPreviousDirectory()
                if(!FilterPTGFolders.isEmpty){
                    self.SDCardFileListTable.reloadData()
                    ShowToast(message: "Empty folder")
                }
                else{
                    PICkit_Custom_Alert(title: "Browse SD card", content: "Can't find PTG images", oneButton: true, image: "X-icon")
                }
            }
        }
    }
    
    func bleCommandResponseData(command: UInt8, data: Any){
        print("[FileManagerVC] bleCommandResponseData")
        
        if(command == PICkit_OpCode.BLE_PTG_BROWSE_SD_CARD.rawValue){
            if data is [String]{
                let files = data as! [String]
                
                if(SelectedFile != "" && SelectedFile != nil){
                    if(SelectedFile.lowercased().contains(".ptg") == false){
                        HideBackButton = false
                    }
                }
                if(IsRootDirectory()){
                    if(!HideBackButton){
                        HideBackButton = true
                    }
                    SelectedFile = ""
                    PTGFolders.removeAll()
                    PTGFolders = files
                }
                FilterPTGFolders.removeAll()
                FilterPTGFolders = files
                SDCardFileListTable.reloadData()
                print("Update PTG list.path = \(String(decoding: BrowseSDCardPath, as: UTF8.self))")
            }
        }
    }
}
