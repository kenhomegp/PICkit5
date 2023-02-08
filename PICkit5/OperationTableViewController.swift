//
//  OperationTableViewController.swift
//  PICkit5
//
//  Created by TestPC on 2022/5/14.
//

import UIKit

class OperationTableViewController: UITableViewController, bleUARTCallBack {

    @IBOutlet weak var opImage: UIImageView!
    
    @IBOutlet weak var opLabel: UILabel!
    
    var bleUart : bleUART?
    
    var SelectedFile : String!
    
    var SelectedPeripheral : String!
    
    var Command : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        #if !targetEnvironment(simulator)
            if bleUart == nil{
                bleUart = bleUART.sharedInstace(option: .Normal)
            }
        #endif
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        #if !targetEnvironment(simulator)
            bleUart?.callback = self
        #endif
    
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        if(section == 0){
            let cell = tableView.dequeueReusableCell(withIdentifier: "OperationLabelCell") as! SectionLabelTableViewCell

            //cell.LabelImage.image = UIImage(named: "Configuration")
        
            return cell
        }
        else{
            let cell = tableView.dequeueReusableCell(withIdentifier: "SeparatorLine")
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if(section == 1){
            return 4
        }
        else{
            return 65
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if(section == 1){
            return 5
        }
        else{
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "opCell", for: indexPath) as! OperationTableViewCell

        // Configure the cell...
        if(indexPath.row == 0){
            //cell.setCell(img_name: "Check_img", label: "Blank Check")
            cell.setCell(img_name: "BlankCheck", label: "Blank Check")
            cell.accessoryType = .disclosureIndicator
        }
        else if(indexPath.row == 1){
            //cell.setCell(img_name: "Erase_img", label: "Erase")
            cell.setCell(img_name: "Erase", label: "Erase")
            cell.accessoryType = .disclosureIndicator
        }
        else if(indexPath.row == 2){
            //cell.setCell(img_name: "Write_img", label: "Write")
            cell.setCell(img_name: "Program", label: "Write")
            cell.accessoryType = .disclosureIndicator
        }
        else if(indexPath.row == 3){
            //cell.setCell(img_name: "Verify_img", label: "Verify")
            cell.setCell(img_name: "Verify", label: "Verify")
            cell.accessoryType = .disclosureIndicator
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print("Select device:\(indexPath.row)")
        
        if(indexPath.row == 0){
            self.Command = "Blank Check"
        }
        else if(indexPath.row == 1){
            self.Command = "Erase"
        }
        else if(indexPath.row == 2){
            self.Command = "Write"
        }
        else if(indexPath.row == 3){
            self.Command = "Verify"
        }
        
        self.performSegue(withIdentifier: "StatusSegue", sender: self)
        /*
        if(indexPath.row >= 1){
            self.performSegue(withIdentifier: "StatusSegue", sender: self)
        }
        else{
            tableView.deselectRow(at: indexPath, animated: true)
        }*/
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        
        print("[OperationTableViewController]segue id = \(segue.identifier ?? "")")
        
        let vc = segue.destination as! StatusViewController
        
        vc.SelectedPeripheral = self.SelectedPeripheral
        vc.SelectedFile = self.SelectedFile
        vc.OperationCommand = self.Command
    }
    
    // MARK: - bleUARTCallBack delegate
    func bleDidDisconnect(error:String){
        self.performSegue(withIdentifier: "OperationDidDisconnect", sender: self)
    }
    
}
