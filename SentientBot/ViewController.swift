//
//  ViewController.swift
//  SentientBot
//
//  Created by Amit Gupta on 10/20/20.
//

import UIKit
import WebKit
import MessageKit
import InputBarAccessoryView
import SwiftyJSON
import Alamofire

class ViewController: MessagesViewController {
    
    var messages: [Message] = []
    var member: Member!
    var memberBot: Member!
    var prediction: String?
    let uploadURL = "https://l47syleshe.execute-api.us-east-1.amazonaws.com/Predict/8c4c67d7-e28b-4ebb-814b-5e5d11990a44"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        member = Member(senderId: "A1", displayName: " ", color: .yellow)
        memberBot = Member(senderId: "A2", displayName: "Bot", color: .blue)
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messageInputBar.delegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        
        botSays("Welcome my friend!! How are you doing?")
    }
    
    func processUserInput(text: String) {
        print("Should be processing text now:",text)
        // Removed the line; the bot was being too chatty!!
        //botSays(acknowledgeUserInput(text))
        

        let mood = getMoodFromAI(text: text)
        /*
         Removed this set of lines; getting the response from the clusyre
         */
        //let resp = getResponseFromMood(mood)
        // Removed the line; the bot was being too chatty!!
        //botSays(resp)
        
    }
    
    func getMoodFromAI(text: String) -> String {
        print("Should be sending text to AI:",text)
        callAI(text)
        let r = "TODO"
        return r
    }
    
    func getResponseFromMood(_ text: String) -> String {
        let choices=["happy":["What makes you happy?",
                              "Glad to know that you are doing well",
                              "It is so good to see you being so positive"],
                     "sad":["What makes you sad?",
                            "Things will get better!!",
                            "I am so sorry"],
                     "TODO":["T1","T2","T3","T4","T5"]
        ]
        guard let m = choices[text] else {return "Missing response"}
        let r=Int.random(in: 0..<m.count)
        let resp = m[r]
        
        return resp
    }
    
    func botSays(_ text: String) {
        print("Bot says:",text)
        let newMessage = Message(
            member: memberBot,
            text: text,
            messageId: UUID().uuidString)
        
        messages.append(newMessage)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    func userSays(_ text: String) {
        print("User says:",text)
        let newMessage = Message(
            member: member,
            text: text,
            messageId: UUID().uuidString)
        
        messages.append(newMessage)
        messagesCollectionView.reloadData()
        messagesCollectionView.scrollToBottom(animated: true)
    }
    
    func acknowledgeUserInput(_ text: String)->String {
        let choices=["I heard you",
                     "Did you say:"+text+"?",
                     "Got it!!"]
        let r=Int.random(in: 0..<choices.count)
        let resp = choices[r]
        return resp
    }
    
    
}

// Conform to protocol MessageDataSource

extension ViewController: MessagesDataSource {
    
    func numberOfSections(
        in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func currentSender() -> SenderType {
        return member
    }
    
    func messageForItem(
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> MessageType {
        
        return messages[indexPath.section]
    }
    
    func messageTopLabelHeight(
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 12
    }
    
    func messageTopLabelAttributedText(
        for message: MessageType,
        at indexPath: IndexPath) -> NSAttributedString? {
        
        return NSAttributedString(
            string: message.sender.displayName,
            attributes: [.font: UIFont.systemFont(ofSize: 12)])
    }
}

// Conform to protocol MessagesLayoutDelegate

extension ViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType,
                           at indexPath: IndexPath,
                           with maxWidth: CGFloat,
                           in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        
        return 0
    }
}

// AI Integration

extension ViewController {
    
    func callAI(_ text:String) {
        
        let params=["sentence":text]
        AF.request(uploadURL, method: .post, parameters: params, encoding: JSONEncoding.default).responseJSON { response in
            
            //debugPrint("AF.Response:",response)
            switch response.result {
            case .success(let value):
                var json = JSON(value)
                //debugPrint("Initial value is ",value)
                //debugPrint("Initial JSON is ",json)
                let body = json["body"].stringValue
                //debugPrint("Initial Body is ",body)
                json = JSON.init(parseJSON: body)
                //debugPrint("Second JSON is ",json)
                let predictedLabel = json["predicted_label"].stringValue
                debugPrint("Predicted label:",predictedLabel)
                let resp = self.getResponseFromMood(predictedLabel)
                self.botSays(resp)
                self.prediction=predictedLabel
            case .failure(let error):
                print("\n\n Request failed with error: \(error)")
            }
        }
    }
}

// Conform to protocol MessagesDisplayDelegate

extension ViewController: MessagesDisplayDelegate {
    func configureAvatarView(
        _ avatarView: AvatarView,
        for message: MessageType,
        at indexPath: IndexPath,
        in messagesCollectionView: MessagesCollectionView) {
        
        let message = messages[indexPath.section]
        let color = message.member.color
        avatarView.backgroundColor = color
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {

        let corner: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight: .bottomLeft
        return .bubbleTail(corner, .pointedEdge)

    }
}

// Conform to protocol InputAccessoryViewDelegate

extension ViewController: InputBarAccessoryViewDelegate {
    func inputBar(
        _ inputBar: InputBarAccessoryView,
        didPressSendButtonWith text: String) {
        
        //print("Just got a new message",text)
        /*
         let newMessage = Message(
         member: member,
         text: text,
         messageId: UUID().uuidString)
         
         messages.append(newMessage)
         */
        
        inputBar.inputTextView.text = ""
        
        userSays(text)
        processUserInput(text: text)
        
        //messagesCollectionView.reloadData()
        //messagesCollectionView.scrollToBottom(animated: true)
    }
    
    func onTextViewDidChangeAction() {
        
    }
    //func onTextViewDidChangeAction(InputBarButtonItem, InputTextView) -> Void)
}

// MARK -- Member struct used for Messages

struct Member: SenderType, Equatable {
    var senderId: String
    var displayName: String
  var color: UIColor
}

struct Message: MessageType {
  let member: Member
  let text: String
  let messageId: String

  var sender: SenderType {
    return member
  }
  
  var sentDate: Date {
    return Date()
  }
  
  var kind: MessageKind {
    return .text(text)
  }
}

