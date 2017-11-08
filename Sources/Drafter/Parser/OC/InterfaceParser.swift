//
//  InterfaceParser.swift
//  Drafter
//
//  Created by LZephyr on 2017/10/31.
//

import Foundation

// TODO: - 代码优化

class InterfaceParser: ParserType {
    
    func parse(_ tokens: Tokens) -> [ClassNode] {
        let parser = categoryParser <|> classParser
        if case .success(let (result, _)) = parser.continuous.parse(tokens) {
            return distinct(result)
        } else {
            return []
        }
    }
    
    // v1
//    let parser = curry(ClassNode.init)
//            <^> (token(.interface) *> token(.name)).map({ $0.text })
//            <*> (curry(ClassNode.init(clsName:)) <^> (curry({ $0.text }) <^> token(.colon) *> token(.name))
//            <*> token(.name).separateBy(token(.comma)).between(l, r).map({ $0.map { $0.text } })
}

// MARK: - Parser

extension InterfaceParser {
    
    /// 解析类型定义
    /**
     classDecl = '@interface' className (':' className)* protocols
     className = NAME
     protocols = '<' NAME (',' NAME)* '>' | ''
     */
    var classParser: Parser<ClassNode> {
        let lAngle = token(.leftAngle)
        let rAngle = token(.rightAngle)
        
        // @interface xx : xx <xx, xx>
        let parser = curry(ClassNode.init)
            <^> token(.interface) *> token(.name) => stringify
            <*> trying(token(.colon) *> token(.name)) => toClassNode
            <*> trying(token(.name).separateBy(token(.comma)).between(lAngle, rAngle)) => stringify
        return parser
    }
    
    /// 解析分类定义
    /**
     extension = '@interface' className '(' ')' protocols
     className = NAME
     protocols = '<' NAME (',' NAME)* '>' | ''
     */
    var categoryParser: Parser<ClassNode> {
        // TODO: 优化
        let lParen = token(.leftParen)
        let rParen = token(.rightParen)
        let lAngle = token(.leftAngle)
        let rAngle = token(.rightAngle)
        
        // @interface xx(xx?) <xx, xx>
        return curry(ClassNode.init)
            <^> token(.interface) *> token(.name) => stringify
            <*> trying(token(.name)).between(lParen, rParen) *> pure(nil) // 分类的名字是可选项, 忽略结果
            <*> trying(token(.name).separateBy(token(.comma)).between(lAngle, rAngle)) => stringify
    }
}

// MARK: - Helper

extension InterfaceParser {
    /// 将一个Token转换成ClassNode类型
    var toClassNode: (Token?) -> ClassNode? {
        return { token in
            if let token = token {
                return ClassNode(clsName: token.text)
            } else {
                return nil
            }
        }
    }
    
    /// 合并相同结果
    func distinct(_ nodes: [ClassNode]) -> [ClassNode] {
        guard nodes.count > 1 else {
            return nodes
        }
        
        var set = Set<ClassNode>()
        for node in nodes {
            if let index = set.index(of: node) {
                set[index].merge(node) // 合并相同的节点
            } else {
                set.insert(node)
            }
        }
        
        return Array(set)
    }
}
