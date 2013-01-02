package sortBookMarkOfSafari;

import java.io.*;
import java.util.ArrayList;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.transform.*;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.*;

public class SortBookMarkOfSafari {
	//XMLファイルのルート
	public static Element root;
	//操作する箇所のルート
	public static Element top;
	public static Document doc = null;
	//なんか定義を読み込んでくれないので自分で定義→成功
	public static final short ELEMENT_NODE = Text.ELEMENT_NODE;
	public static final short TEXT_NODE = Text.TEXT_NODE;
	public static String inputFileName = null;
	public static String outputFileName = null;
	public static int bIgnore = 0;
	public static int bReverse = 0;

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		if(setArgs(args)){
			doIt();
		}
		else{
			System.out.println("setArgs fail.");
		}
		//test();
	}
	public static boolean setArgs(String[] args) {
//		System.out.println("setArgs Start.");
//		int len = args.length;
//		for(int i = 0;i < len; i++){
//			System.out.println(args[i]);
//		}
		try {
			//1つめはInputFile
			inputFileName = args[0];
			//2つめはOutputFile
			outputFileName = args[1];
			//3つめはbIgnore
			bIgnore = Integer.parseInt(args[2]);
			bReverse = Integer.parseInt(args[3]);
		} catch (Exception e) {
			e.printStackTrace();
		}
		return true;
	}

	public static void doIt(){
		System.out.println("SortBookmarkOfSafari Start.");
		getRoot();
		if(getTop() == false){
			return;
		}
		if(sortArray(top) == false){
			return;
		}
		System.out.println("sortArray Success.");
		outputFile();
		System.out.println("SortBookmarkOfSafari End.");
	}
	public static void outputFile(){
		try {
			TransformerFactory transFactory = TransformerFactory.newInstance();
			Transformer transformer;
			transformer = transFactory.newTransformer();
			DOMSource source = new DOMSource(doc);
			File newXML = new File(outputFileName);
			FileOutputStream os = new FileOutputStream(newXML);
			StreamResult result = new StreamResult(os);
			transformer.transform(source, result);	
		} catch (Exception e) {
			e.printStackTrace();
		}
		System.out.println("outputFile Success.");
	}

	//<array>以下の<dict>のソートを行う。再帰的に全てやる
	public static boolean sortArray(Element array){
		//NodeList nList = top.getElementsByTagName("dict");
		NodeList nList = array.getChildNodes();
		ArrayList<DictUnit> dictUnit = makeDictUnit(nList);
		if(dictUnit == null){
			return false;
		}
		//dictUnitに従って実際に入れ替える
		//バブルソートを行う
		doBubbleSort(array, nList, dictUnit);
		return true;
	}

	//arrayを再構成する
	public static void doBubbleSort(Element array, NodeList nList, ArrayList<DictUnit> dictUnit){
		Node clone = array.cloneNode(true);
		//array.replaceChild(nList.item(1), nList.item(0));
		int len = dictUnit.size();
		//まずdictUnitを並び替える
		for(int i = 0; i < len; i++){
			for(int j = 0; j < len - (i+1); j++){
				DictUnit left = dictUnit.get(j);
				DictUnit right = dictUnit.get(j + 1);
				//左辺の方が大きかったら
				if(judge(left, right) == false){
					//交換する
					dictUnit.set(j, right);
					dictUnit.set(j + 1, left);
				}	
			}
		}

		//arrayを作り直す
		len = nList.getLength();
		//removechildを使うとnListの中身が消えて厄介なので、念のため後ろから削除していく
		for(int i = len-1; 0 <= i; i--){
			Node n = nList.item(i);
			if(n != null){
				array.removeChild(n);
			}
		}

		NodeList nList2 = clone.getChildNodes();
		//dictUnitの順番にappendChildしていく
		len = dictUnit.size();
		for(int i = 0; i < len; i++){
			int index = dictUnit.get(i).index;
			//index番目のnList2を足す
			array.appendChild(nList2.item(index));
			//appendChildで消えた分、残りのインデックスを修正する
			for(int j = i+1; j < len; j++){
				int a = dictUnit.get(j).index;
				if(a > index){
					dictUnit.get(j).index -= 1;
				}
			}
		}
	}

	//dictUnitを作成。
	//失敗したらnulを返す
	public static ArrayList<DictUnit> makeDictUnit(NodeList nList){
		int len = nList.getLength();
		ArrayList<DictUnit> dictUnit = new ArrayList<DictUnit>();
		for(int i = 0; i < len; i++){
			Node node = nList.item(i);
			//これはdictであるはず
			if(node.getNodeType() == ELEMENT_NODE){
				DictUnit dict = new DictUnit();
				dict.index = i;
				Element element = (Element)node;
				String key = getFirstKeyValue((Element)node);
				//ファイル
				if(key.equals("URIDictionary")){
					dict.isDir = false;
					Element e = (Element)(element.getElementsByTagName("dict")).item(0);
					dict.name = key2Str(e, "title");
					dictUnit.add(dict);
				}
				//フォルダ
				else if(key.equals("Children")){
					dict.isDir = true;
					dict.name = key2Str(element, "Title");
					Element e = (Element)(element.getElementsByTagName("array")).item(0);
					//再帰的にsortArray
					sortArray(e);
					dictUnit.add(dict);
				}
				//空のフォルダ
				else if(key.equals("Title")){
					dict.isDir = true;
					dict.name = key2Str(element, "Title");
					dictUnit.add(dict);
				}
				else{
					System.out.println("Unknown Dict.");
					return null;
				}
			}
		}
		return dictUnit;
	}

	//一つ目のkeyの値を取得
	public static String getFirstKeyValue(Element array){
		Element e = (Element)(array.getElementsByTagName("key")).item(0);
		return e.getFirstChild().getNodeValue();
	}

	//２つのdictUnitの大きさを定義、比較する
	//rightが大きければtrue、そうれなければfalse
	public static boolean judge(DictUnit left, DictUnit right){
		boolean bRet;
		//まず、ディレクトリを優先
		if(left.isDir == true && right.isDir == false){
			bRet = true;
		}
		else if(left.isDir == false && right.isDir == true){
			bRet = false;
		}
		else{
			//2つが同じ種類であったら文字列で比較
			//一応大文字、小文字を意識。無視するならcompareToIgnoreCase(str)
			if(bIgnore == 1){
				if(left.name.compareToIgnoreCase(right.name) > 0){
					bRet = false;
				}
				else{
					bRet = true;
				}
			}
			else{
				if(left.name.compareTo(right.name) > 0){
					bRet = false;
				}
				else{
					bRet = true;
				}
			}
		}
		//逆順ソートなら反転させる
		if(bReverse == 1){
			bRet = !bRet;
		}
		return bRet;
	}

	//eの子ノードからSafariブックマーク形式で<key>プロパティがkeyと一致するものの<String>プロパティを返す
	//見つからなかったらnull
	public static String key2Str(Element e, String key){
		//NamedNodeMap nodeMap = e.getAttributes();
		NodeList list = e.getChildNodes();
		int len = list.getLength();
		for(int i = 0; i < len; i++){
			Node node = list.item(i);
			//エレメント以外は弾く
			if(node.getNodeType() == ELEMENT_NODE){
				String nodeName = node.getNodeName();
				String nodeValue = node.getFirstChild().getNodeValue();
				if(nodeName.equals("key") && nodeValue.equals(key)){
					//次のノードを見てみる。多分keyの次はあるはずだからあると決め打ち
					for(int j = i+1; j < len; j++){
						node = list.item(j);
						//はじめにkeyの次にあるELEMENTが対応するstringであるはず！
						if(node.getNodeType() == ELEMENT_NODE){
							if(node.getNodeName().equals("string")){
								return node.getFirstChild().getNodeValue();
							}
							break;
						}
					}
				}
			}
		}
		return null;
	}
	//ブックマークメニューを示す<array>を取得
	public static boolean getTop(){
		//多分一番外側のarrayの2番目のdictがブックマークバーのはず。一応調べる
		Element firstArray = (Element)(root.getElementsByTagName("array").item(0));
		NodeList list = firstArray.getChildNodes();
		int len = list.getLength();
		for(int i = 0; i < len; i++){
			Node n = list.item(i);
			if(n.getNodeType() == ELEMENT_NODE){
				String s = key2Str((Element)n, "Title");
				if(s != null && s.equals("BookmarksBar")){
					//dict = (Element)n;
					top = (Element)(((Element) n).getElementsByTagName("array").item(0));
					if(top == null){
						System.out.println("Can't find array in dict of BookmarkBar.");
						return false;
					}
					else{
						System.out.println("getTop Success.");
						return true;
					}	
				}
			}
		}
		System.out.println("getDict false.");
		return false;
	}
	//指定したXMLファイルのRootを取得
	public static boolean getRoot(){
		File fileObject = new File(inputFileName);
		DocumentBuilder docBuilder = null;
		try {
			docBuilder = DocumentBuilderFactory.newInstance().newDocumentBuilder();
			doc = docBuilder.parse(fileObject);
		} catch (Exception e) {
			e.printStackTrace();
		}
		root = doc.getDocumentElement();
		System.out.println("getRoot Success.");
		return true;
	}

	/*public static void test(Element e, Node n){	
		e.appendChild(n);
	}
	public static void prt(Node n){
		System.out.println("Name : " + n.getNodeName() + ", Type : " + n.getNodeType()  + ", Value : "+ n.getNodeValue());	
	}
	public static void prt(NodeList nList){
		System.out.println("prt start!");
		int len = nList.getLength();
		for(int i = 0; i < len; i++){
			Node n = nList.item(i);
			System.out.println("Name : " + n.getNodeName() + ", Type : " + n.getNodeType()  + ", Value : "+ n.getNodeValue());
		}
		System.out.println("prt end!");
	}
	public static void prt(ArrayList<DictUnit> d){
		System.out.println("prt start!");
		int len = d.size();
		for(int i = 0; i < len; i++){
			DictUnit du = d.get(i);
			System.out.println("index : " + du.index + ", Name : " + du.name  + ", isDir : "+ du.isDir);
		}
		System.out.println("prt end!");
	}
	public static void p(String s){
		System.out.println("p : " + s);	
	}*/
}
